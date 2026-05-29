# Patches

Drop source-tree patches here, applied before `feeds update`:

- `patches/lede/*.patch` — applied when building **lede**
- `patches/immortalwrt/*.patch` — applied when building **immortalwrt**

Generate a patch from your build tree:

```bash
cd build/lede
git diff > ../../patches/lede/my-fix.patch
```

Patches run with `patch -p1` from the source root.
