# fast-dupes-finder

This repository proposes clean, fast and shell based scripts for identifying
finding duplicate files in a folder.

No need to read this though, it's just information on the script, but feel free
to just copy and paste it in you shell and observe the `./trash` folder filling
with files having duplicates in your `./` folder.

## Where does this come from/what can it be used for

Basically, I save my phone's photos on my NAS on which I cannot install APT
packages or something like [fdupes](https://github.com/adrianlopezroche/fdupes).

Many times I messed up my photos save and my Phone re-sent many picture to my
NAS, but with different names, with no clear pattern: it could append
`-1`, `-2`, ... to the name, but some photos already existed with `-1`, `-2`,
... in their name without being duplicates.

Therefore, I had to concretely compare files' contents to know if there were
duplicate of each other. However, the folder contained over 9'000 files,
requiring a not so dumb algorithm to complete.

## Why is this fast

### Reducing the number of comparisons

The naive algorithm would be to take each file and compare it to every other:

```pseudo-code
FOR file1 IN folder:
    FOR FILE2 IN folder:
        IF file1 == file2:
            OUTPUT "file1 is a duplicate of file2"
        ENDIF
    ENDFOR
ENDFOR
```

This goes in a $O(N^2)$ basis, meaning that with my 9'000 files, there would be
around $9'000^2$ file comparisons.

#### What can be found quickly/cheaply

In order to reduce this, we need to identify when a comparison is not needed. To
know this "in advance", meaning before we have to actually compare the files,
our only tools lie in the files' indexed information. These indexed information
allow us to know more about the file without reading them.

For example the file size is an indexed information: using `ls -l` shows the
file size without requiring to read it, because our kind OS and file system
saves this information for us. This is instantaneous and required 0 file read,
so cheap operation for us.

As you may see it coming, we will use files sizes to reduce the number of
comparisons: indeed, we know that if 2 files differ in size, they will not be
identical, no need to actually compare them to know that.

Hence, instead of comparing each file to each other in the folder, we will
first find all sizes of each files (fast, `ls -l` more or less), sort all the
sizes (fast, sorting 9'000 numbers once), go through this list of sorted sizes
and if there are 2 successive sizes identical, keep it for later (fast, go once
through a list of 9'000 numbers).

#### Using the duplicate sizes to reduce the number of comparisons

With this reduced number of sizes, we cheaply identified all sizes for which
there are at least 2 files having this size.

Now, instead of comparing each file to the others, we can go through each size,
find files of that size (fast), and compares these files among them.

```pseudo-code
FOR size IN duplicated_sizes:
    FOR file1 WITH SIZE size:
        FOR file2 WITH SIZE size NOT BEING file1:
            IF file1 == file2:
                OUTPUT "file1 is a duplicate of file2"
            ENDIF
        ENDFOR
    ENDFOR
ENDFOR
```

#### How much faster can we expect to be?

Let's say we actually have $M$ duplicate sizes in the folder
($M\leq \frac{N}{2}$).

Among them, we need to identify how many "honest" file size collisions there
are. Computing this can be boldly approximated with the
[Birthday Paradox](https://en.wikipedia.org/wiki/Birthday_paradox#Approximations)
collision probability computation work. Following this, the number of "people"
becomes our number of files ($N$), while the number of "days" is the number of
possibles picture sizes. This is not easy to fairly approximate and depend on
the structure of uploaded photos. If someone with cool knowledge in photography
format compression would like to help this is welcome. Assuming we can know the
number of different sizes for our pictures ($d$), our probability of collision
approximate to $p(n,d)\approx1-e^{-\frac{N^2}{2\times d}}$, meaning our
expected number of collisions follows, by linearity, this approximation:
$c\approx N\times(1-e^{-\frac{N^2}{2\times d}})$

Hopefully, this is very low, and allows us to ensure that when we compare 2
files, we very likely compare 2 identical files, reducing the number of useless
comparisons. Empirically at least it's really fine.

### Fast comparison

Last but not least, we want to ensure that when we compare 2 files, we can very
fast know if 2 files are different or not. I have seen some people online
suggesting hashing both files with MD5 and comparing the hashes. Although this
probably work, I see 2 issues:

- hashing can have collisions (although unlikely but still, you don't want to
delete precious pictures by mistake)
- hashing requires going through both files in whole

Therefore, I prefer to use `cmp` which, conceptually, goes through both files at
the same time and stops as soon as it encounters 2 byte that differ. This solves
both the previous issues.
