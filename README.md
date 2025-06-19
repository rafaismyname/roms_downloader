# ROMs Downloader

A tool to download files from a index.

Coincidently, can be used for downloading ROMs collections in the case you legally can own those ROMs.

I plan to add more utils that I often need for my voluntary work at my church and dog shelter like decompressing the downloaded files automatically.

## Data

The data inside `lib/data/consoles.dart` is merely fictional for testing purposes, placeholder, template.
I do not own nor recommend those sources, as a matter of fact, the first step setting up this app to run locally is to edit that file, removing all the non-sense data and bringing your own indexes urls.

## Instructions

- Clone.
- Update `lib/data/consoles.dart` deleting the placeholder data and bringing your own indexes.
- Build, run, be happy.
- Treat others as you would like to be treated.

## Features/Future

- [x] Load catalogs async
- [x] Display multiple catalogs
- [x] Parallel downloads
- [x] Search title
- [x] Change download destination folder
- [ ] Unzip files according to definitions per console (what files should be extracted, formats, etc)
- [ ] In-Library detection should be per title, and not per file existence (eg.: ignore extension)
- [ ] Background Downloader
- [ ] Background Unzip
- [ ] Select all
- [ ] Sort list
- [ ] Ignore (hide) file
- [ ] Manually Mark as in-library
- [x] Android build setup
- [x] Mac build setup
- [ ] Windows build setup
- [ ] Linux build setup
- [ ] ~~iOS build setup~~ No iOS support for now, cry about it.

## Technologies

- Flutter
- Seratonin

## Tests

Not yet, feel free to add tests.

## Stable?

Heck no! I will still bring a lot of breaking changes to this.

## License

MIT

## Author(s)

- [rafaismyname](https://github.com/rafaismyname)
- Your name here? open a PR!
