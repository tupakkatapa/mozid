# mozid
a command-line tool for retrieving the extension ID from a Firefox `.xpi` add-on package. It automates the process of downloading a `.xpi` file from Mozilla's Add-ons website, extracting the `manifest.json`, and displaying the extension's unique ID.

This tool was inspired by the difficulty of retrieving the extension ID when non-declarative installations are blocked in Firefox, as discussed in this [thread](https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/17).

## Usage
Clone the repository and make the script executable:

```bash
git clone https://github.com/tupakkatapa/mozid.git
cd mozid
chmod +x mozid.sh
```

Run the script by passing it a Firefox add-on URL as an argument:
```bash
./mozid.sh <url>
```

