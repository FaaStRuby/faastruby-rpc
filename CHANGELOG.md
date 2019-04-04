# Changelog

## 0.2.7 - Apr 7 2019
- Make env vars match the ones on faastruby-cli

## 0.2.6 - Mar 18 2019
- Multiple calls to the same function no longer overwrite each other.
- Use Oj mode :compat when converting keyword arguments to JSON.

## 0.2.5 - Mar 16 2019
- Add `inspect` method for when `p` is called. Ex: p Constant.call
- Added alias methods `value` - `Constant.call.value`
- Remove references to workspace from README, as the workspace name is not part of the URI path anymore.

## 0.2.4 - Mar 14 2019
- Only capitalize first letter when creating constant to assign to fulction call

## 0.2.3 - Mar 11 2019
- Add support for faastruby 0.5

## 0.2.2 - Mar 8 2019
- Improved response string from invoked function when there's an error.
- Catch method missing calls and try them against the result once it arrives

## 0.2.1 - Jan 3rd 2019
- Pass a block when calling a function and the code will be executed when the function responds, and the block's return value will replace the function's response body

## 0.2.0 - Dec 31 2018
- Redesigned UX for calling of external functions

## 0.1.3 - Dec 15 2018
- Add test helper to stub invoke()

## 0.1.2 - Dec 9 2018
- Disable SSLv2, v3 and compression when calling invoke.

## 0.1.1 - Dec 9 2018 - First release
