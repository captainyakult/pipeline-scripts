Takes a single param `$1`, the name of a config within the `wmts-to-cmts/configs` folder (minus the extension).

1. Downloads WMTS files using the configuration `wmts-to-cmts/configs/$1.json` and creates a CMTS config file as `data/cmts_configs/wmts/$1/`
2. Creates CMTS at `data/cmts/wmts/$1/`.
