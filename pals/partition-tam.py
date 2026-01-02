import string
import re
import itertools
import typing
import sys
import time, datetime

from collections import Counter
from pathlib import Path
from math import log10


__punctuations = re.compile("[" + re.escape(string.punctuation) + "«»…" + "]+")

__tool_delta = {
    'itrameur': -1.0,
}


def progress(x):
    start = time.time()
    data = list(x) + [None]
    L = len(data) - 1
    for i, dat in enumerate(data):
        if i != L:
            print(f"{100*i/L:.2f}%", end='\r', file=sys.stderr)
            yield dat
        else:
            print(f"100.00% in {datetime.timedelta(seconds=time.time()-start)}", file=sys.stderr)
            return


def flatten(iterable: typing.Iterable) -> list:
    return list(itertools.chain.from_iterable(iterable))


def log_binomial(n: int, k: int) -> float:
    n = int(n)
    k = int(k)

    if n < 0 or k < 0:
        raise ValueError('binomial: found number < 0')
    if k > n:
        raise ValueError('binomial: k > n')

    if k == 0 or k == n:
        return 0.0

    result = 0
    K = min(k, n - k)
    for i in range(K):
        result += log10(n - i) - log10(i + 1)
    return result


def log_hypergeometric(T: int, t: int, F: int, f: int) -> float:
    a = log_binomial(F, f)
    b = log_binomial(T - F, t - f)
    c = log_binomial(T, t)
    return a + b - c


def lafon_specificity(T: int, t: int, F: int, f: int, tool_emulation: str = 'None') -> float:

    if any((t < 0, T < 0, f < 0, F < 0)):
        raise ValueError('Lafon specificity: found count < 0')

    if t > T:
        if tool_emulation == 'itrameur': return 0.0
        raise ValueError('token count greater than corpus size')
    if f > t:
        if tool_emulation == 'itrameur': return 0.0
        raise ValueError('token count greater than subcorpus size')
    if f > F:
        if tool_emulation == 'itrameur': return 0.0
        raise ValueError('token subcorpus count greater than token corpus count')
    if t > T:
        if tool_emulation == 'itrameur': return 0.0
        raise ValueError('subcorpus bigger than corpus')

    # using a symmetry in hypergeometric distribution that is quicker to compute
    specif = log_hypergeometric(T, F, t, f) + __tool_delta.get(tool_emulation, 0.0)

    if log10(f + 1) > log10(t + 1) + log10(F + 1) - log10(T + 2):
        specif = -specif

    return specif


def source_count(
    source: list[str | Path],
    punctuations: str = 'ignore',
    case_sensitivity: str = 'sensitive'
) -> Counter:

    ignore_punctuations = punctuations == 'ignore'
    do_fold = case_sensitivity in ('i', 'insensitive')
    result = Counter()

    for file in source:
        with open(file, 'r', encoding='utf-8') as input_stream:
            for line in input_stream:
                line = line.strip()
                if not line:
                    continue
                if ignore_punctuations and __punctuations.fullmatch(line):
                    continue
                if do_fold:
                    line = line.casefold()
                result[line] += 1

    return result


def get_counts(
    sources: list[list[str | Path]],
    punctuations: str = 'ignore',
    case_sensitivity: str = 'sensitive'
) -> tuple[int, list[Counter], Counter, list[Counter]]:

    fs = [source_count(source, punctuations, case_sensitivity) for source in sources]
    F = Counter()
    ts = []
    for count in fs:
        F.update(count)
        x, y = zip(*count.most_common())
        ts.append(sum(y))

    T = sum(ts)

    return T, ts, F, fs


def run(
    inputs: list[str | Path],
    n_firsts: int = 1000,
    punctuations: str = 'ignore',
    case_sensitivity: str = 'sensitive',
    tool_emulation: str = 'None',
) -> None:

    if len(inputs) < 2:
        raise ValueError('At least 2 sources required')

    if tool_emulation == 'itrameur':
        given_punctuations = punctuations
        punctuations = 'ignore'

        if given_punctuations != punctuations:
            print(
                f"WARNING: itrameur emulation => punctuations set to {punctuations}\n",
                file=sys.stderr
            )

    T, ts, F, fs = get_counts(progress(inputs), punctuations, case_sensitivity)

    n_firsts = (n_firsts if n_firsts > 0 else len(inputs))
    names = [f'part-{nth}' for nth in range(1, len(inputs)+1)]

    # chemin du fichier de résultats
    SCRIPT_DIR = Path(__file__).parent
    resultat_file = SCRIPT_DIR / 'resultats-partition-tam.txt'

    with open(resultat_file, 'w', encoding='utf-8') as f:
        # impressions sur stderr (progression, noms des partitions)
        print(file=sys.stderr)
        cpy = [lst[:] for lst in inputs]
        maxlen = max(len(lst) for lst in cpy)
        cpy = [item + [''] * (maxlen - len(item)) for item in cpy]
        print(*names, sep="\t", file=sys.stderr)
        for j in range(maxlen):
            print(*[cpy[i][j] for i in range(len(cpy))], sep="\t", file=sys.stderr)
        print(file=sys.stderr)

        # contenu principal dans le fichier
        header = ['item', 'total'] + flatten([[f'count {name}', f'specif {name}'] for name in names])
        print('\t'.join(header), file=f)

        totals = ['', f'{T}'] + flatten([[f'', f'{t}'] for t in ts])
        print('\t'.join(totals), file=f)

        for item, count in F.most_common(n_firsts):
            specifs = [
                lafon_specificity(
                    T, ts[i], F[item], fs[i][item], tool_emulation=tool_emulation
                )
                for i in range(len(inputs))
            ]

            item_data = [f'{item}', f'{F[item]}'] + flatten(
                [[f'{fs[i][item]}', f'{specifs[i]:.2f}'] for i in range(len(specifs))]
            )
            print('\t'.join(item_data), file=f)

    print(f"\nRésultats enregistrés dans {resultat_file}", file=sys.stderr)


def main(argv=None):
    import argparse

    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter
    )

    # dossier du script lui-même
    SCRIPT_DIR = Path(__file__).parent


    parser.add_argument(
        '--inputs',
        nargs='+',
        default=[str(SCRIPT_DIR / 'contextes-tam.txt')],
        help='Liste des fichiers partitions (par défaut contextes-tam.txt dans le dossier du script)'
    )

    parser.add_argument(
        '-N',
        '--n-firsts',
        type=int,
        default=1000,
        help='Output n first elements in terms of rank in the global corpus (default: %(default)s)',
    )
    parser.add_argument(
        '-p',
        '--punctuations',
        choices=('ignore', 'acknowledge'),
        default='ignore',
        help='What to do with punctuations? (default: %(default)s)'
    )
    parser.add_argument(
        '-s',
        '--case-sensitivity',
        choices=('sensitive', 's', 'insensitive', 'i'),
        default='sensitive',
        help='Set case sensitivity (default: %(default)s)',
    )
    parser.add_argument(
        '-t',
        '--tool-emulation',
        choices=('None', 'itrameur', 'TXM'),
        default='None',
        help='Try to emulate the results of the given tool (default: %(default)s)',
    )

    args = parser.parse_args(argv)

    # s'assurer que inputs est toujours une liste de listes
    if isinstance(args.inputs[0], str):
        args.inputs = [[inpt] for inpt in args.inputs]

    run(**vars(args))


if __name__ == '__main__':
    main()
    sys.exit(0)
