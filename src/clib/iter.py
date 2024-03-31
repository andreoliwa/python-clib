"""Tools for iterators and iterables."""

from itertools import cycle, islice


def roundrobin(*iterables):
    """Get one item from each iterable.

    Recipe credited to George Sakkis.
    Taken from https://docs.python.org/3/library/itertools.html#itertools-recipes

    >>> list(roundrobin('ABC', 'D', 'EF'))
    ['A', 'D', 'E', 'B', 'F', 'C']
    """
    num_active = len(iterables)
    nexts = cycle(iter(it).__next__ for it in iterables)
    while num_active:
        try:
            for next in nexts:
                yield next()
        except StopIteration:
            # Remove the iterator we just exhausted from the cycle.
            num_active -= 1
            nexts = cycle(islice(nexts, num_active))
