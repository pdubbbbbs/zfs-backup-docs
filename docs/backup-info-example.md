# Example Backup Info File

Below is an example of the `.info` file generated for monthly backups. This file provides detailed information about the ZFS snapshot that was backed up.

```
Backup created: Fri Apr 25 08:26:58 PM PDT 2025
Source dataset: tank/stage
Snapshot: tank/stage@monthly-202504
Compression: gzip level 9
NAME                       PROPERTY              VALUE                  SOURCE
tank/stage@monthly-202504  type                  snapshot               -
tank/stage@monthly-202504  creation              Fri Apr 25 20:26 2025  -
tank/stage@monthly-202504  used                  0B                     -
tank/stage@monthly-202504  referenced            96K                    -
tank/stage@monthly-202504  compressratio         1.00x                  -
tank/stage@monthly-202504  devices               on                     default
tank/stage@monthly-202504  exec                  on                     default
tank/stage@monthly-202504  setuid                on                     default
tank/stage@monthly-202504  createtxg             68421                  -
tank/stage@monthly-202504  xattr                 on                     default
tank/stage@monthly-202504  version               5                      -
tank/stage@monthly-202504  utf8only              off                    -
tank/stage@monthly-202504  normalization         none                   -
tank/stage@monthly-202504  casesensitivity       sensitive              -
tank/stage@monthly-202504  nbmand                off                    default
tank/stage@monthly-202504  guid                  9685683458526074817    -
tank/stage@monthly-202504  primarycache          all                    default
tank/stage@monthly-202504  secondarycache        all                    default
tank/stage@monthly-202504  defer_destroy         off                    -
tank/stage@monthly-202504  userrefs              0                      -
tank/stage@monthly-202504  objsetid              43228                  -
tank/stage@monthly-202504  mlslabel              none                   default
tank/stage@monthly-202504  refcompressratio      1.00x                  -
tank/stage@monthly-202504  written               0                      -
tank/stage@monthly-202504  logicalreferenced     42K                    -
tank/stage@monthly-202504  acltype               off                    default
tank/stage@monthly-202504  context               none                   default
tank/stage@monthly-202504  fscontext             none                   default
tank/stage@monthly-202504  defcontext            none                   default
tank/stage@monthly-202504  rootcontext           none                   default
tank/stage@monthly-202504  encryption            off                    default
tank/stage@monthly-202504  prefetch              all                    default
```

## Understanding the Info File

The info file contains:

1. **Backup Metadata**:
   - Creation timestamp
   - Source dataset
   - Snapshot name
   - Compression method

2. **ZFS Snapshot Properties**:
   - Type and creation time
   - Size information (used, referenced)
   - Compression ratio
   - Security settings (devices, exec, setuid)
   - Filesystem properties (version, case sensitivity)
   - Caching configuration
   - Advanced properties (encryption, prefetch)

This information is valuable for:
- Troubleshooting backup issues
- Verifying backup content
- Understanding dataset configuration
- Documenting backup history

