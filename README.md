# ROMs Downloader
A tool to download files from an index page.

Coincidentally, it can be used for downloading ROM collections in cases where you **legally** own those ROMs.

I plan to add more utilities that I often need for my voluntary work at my church and dog shelter, like described below in the [Features/Future](#featuresfuture) section.

## Data

The data inside `assets/consoles.json` is **merely fictional** for **testing purposes**, it's a placeholder/template, it was randomly generated and is untested.
I **do not** own nor recommend those sources. As a matter of fact, the first step in setting up this app to run locally is to edit that file, removing all the nonsense data and bringing your own index URLs.

## Downloading builds

I'm currently not relying on releases **JUST BECAUSE**. Meanwhile you can access the latest builds in the [build workflow page](https://github.com/rafaismyname/roms_downloader/actions/workflows/build-and-deploy.yml).
*Note: You must be logged in to GitHub to access the workflow page and download the build.*

## Instructions

- Clone.
- Update `assets/consoles.json` by deleting the placeholder data and bringing your own indexes (or use a custom file in the final app).
- Build, run, be happy.
- Treat others as you would like to be treated.

## Features/Future
- [x] Async loading and display of multiple console indexes/catalogs
- [x] Parallel, independent downloads with background support and tasks queue
- [x] Search and filter titles (by country/language, type, extension, etc.)
- [x] Change and customize download destination folder and settings per console
- [x] Unzip and auto-extract downloaded files (background unzip, in-library detection (extracted/similar-named files))
- [x] Allow custom consoles and settings via JSON
- [x] Navigate/search other consoles while downloads/extractions are in progress
- [ ] Collections/Lists
- [x] Permissions control
- [x] Boxart fetching
- [x] Favorites, filter favorites and favorite list export/import
- [x] Filter by in-library
- [ ] Settings for file cache folder
- [x] Grid viewer
- [ ] Game metadata (rating, description, etc.)
- [ ] List sorting
- [x] Info/About page
- [x] Android, Mac, and Windows support
- [x] Linux arm64 support [Tested on Odin2 Pro Mini via Rocknix (DRM) and RG34XXSP via Knulli and MuOS (FBDEV)]
- [ ] Linux x86_64 support
- [ ] ~~iOS support~~ No iOS support for now, *cry about it*.

## Technologies

- Flutter
- Serotonin

## Tests

Not yet! Feel free to add tests.

## Stable?

**Heck no!** I will still bring a lot of breaking changes to this.

## License

MIT

## Author(s)

- [rafaismyname](https://github.com/rafaismyname)
- Your name here? open a PR!
