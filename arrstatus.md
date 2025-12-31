# Arrstatus

## Description

Arrstatus is a macOS 15+ menubar application that shows current status of several *arr services and download clients. 

## Requirements

- in the menubar itself, it will show aggregated number of current downloads + aggregated speed from all the download clients
- when clicked, it will have several sections, one for each download client, that will list:
- - current download/upload speed (upload applicable for torrents only)
- - opens detail of the client in web when clicked
- next section will be for radarr and then the same for sonarr:
- - listing all the active items (that are downloading, importing or stalled)
- all the settings will be hardcoded for now, we'll add a preferences window later
