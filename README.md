# ROMs Downloader

A tool to download files from an index.

Coincidentally, it can be used for downloading ROM collections in cases where you legally own those ROMs.

I plan to add more utilities that I often need for my voluntary work at my church and dog shelter, like decompressing the downloaded files automatically.

## Data

The data inside `assets/consoles.json` is merely fictional for testing purposes, it's a placeholder/template.
I do not own nor recommend those sources. As a matter of fact, the first step in setting up this app to run locally is to edit that file, removing all the nonsense data and bringing your own index URLs.

## Instructions

- Clone.
- Update `assets/consoles.json` by deleting the placeholder data and bringing your own indexes (or use a custom file in the final app).
- Build, run, be happy.
- Treat others as you would like to be treated.

## Features/Future

- [x] Load console index/catalog async
- [x] Display multiple indexes/catalogs
- [x] Parallel downloads
- [x] Search title
- [x] Change download destination folder
- [x] Independent downloads (start a new download while other is ongoing)
- [x] Unzip downloaded files
- [x] In-Library detection improved to detect extracted files and similar-named content
- [x] Background Downloader
- [x] Background Unzip
- [x] Auto-extract after download
- [x] Tasks Queue
- [x] Filters (like country/language, type, extension, etc.)
- [x] Allow custom consoles (via JSON)
- [x] Allow navigating other consoles and search while download/extraction is in progress
- [ ] Improve file detection system (custom rexeg/extensions per console)
- [x] Custom settings per console (dest. dir/unzip rules/default filters/etc.)
- [x] Permissions control
- [x] Boxart fetching
- [ ] Settings for file cache folder
- [x] Grid Viewer
- [ ] Game metadata fetcher (rating, description...)
- [x] Info/About page
- [x] Android support
- [x] Mac support
- [x] Windows support
- [ ] Linux support (untested)
- [ ] Handheld Linux support (untested)
- [ ] ~~iOS support~~ No iOS support for now, cry about it.

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
