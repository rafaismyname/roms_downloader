# ROMs Downloader

A tool to download files from an index.

Coincidentally, it can be used for downloading ROM collections in cases where you legally own those ROMs.

I plan to add more utilities that I often need for my voluntary work at my church and dog shelter, like decompressing the downloaded files automatically.

## Data

The data inside `lib/data/consoles.dart` is merely fictional for testing purposes, it's a placeholder/template.
I do not own nor recommend those sources. As a matter of fact, the first step in setting up this app to run locally is to edit that file, removing all the nonsense data and bringing your own index URLs.

## Instructions

- Clone.
- Update `lib/data/consoles.dart` by deleting the placeholder data and bringing your own indexes.
- Build, run, be happy.
- Treat others as you would like to be treated.

## Features/Future

- [x] Load console index/catalog async
- [x] Display multiple indexes/catalogs
- [x] Parallel downloads
- [x] Search title
- [x] Change download destination folder
- [x] Independent downloads (start a new download while other is ongoing)
- [ ] Unzip downloaded files (according to definitions per console (what files should be extracted, formats, etc.))
- [ ] In-Library detection should be per title, and not per file existence (eg.: ignore extension)
- [x] Background Downloader
- [ ] Background Unzip
- [ ] Select all
- [ ] Sort list
- [ ] Filters (like country/language, type, extension, etc.) deprecating the hardcoded list filter
- [ ] Allow custom consoles (via JSON)
- [ ] Improve file detection system (custom rexeg per console)
- [ ] Custom settings per console (dest. dir/unzip rules/default filters/etc.)
- [ ] Ignore (hide) file
- [ ] Manually mark as in-library
- [ ] Controller support for improved handheld use
- [x] Android build setup
- [x] Mac build setup
- [ ] Windows build setup
- [ ] Linux build setup
- [ ] ~~iOS build setup~~ No iOS support for now, cry about it.

## Technologies

- Flutter
- Serotonin

## Tests

Not yet! Feel free to add tests.

## Stable?

Heck no! I will still bring a lot of breaking changes to this.

## License

MIT

## Author(s)

- [rafaismyname](https://github.com/rafaismyname)
- Your name here? open a PR!
