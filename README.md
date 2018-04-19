# OneDrive Layout

**NOTE** This repository is archived since OneDrive Files On-Demand is back in Windows 10.

A project born in the removal of placeholder synchronisation for OneDrive for Windows 8.1.

It is well known that OneDrive for Windows 8.1 employs a placeholder technique that gives a user the complete view of his OneDrive, without taking too much space. The trick is to only store the metadata, and acquire the file on demand, either explicitly required by the user (invoking “Make available offine” context menu command), or implicitly when a legacy app tries to access the file.

This behaviour has led to confusion, as some novices cannot figure out how this smart mechanism works. Moreover, when it comes to legacy apps, none of them did the good thing. Often, if not always, legacy code opens a file synchronously. That is already a problem in the past, but most people do not use files over network, and the speed of old hard drives matches that of other old parts of the machine, hence the lag is still bearable. However, to make an online-only file available to a legacy code, which has no concept about a placeholder file, il faut to download the file (i.e., make it available offline). OneDrive sync engine will not be able to know which file it should download, before the user clicks “Open”. That implies a long waiting time between clicking “Open” and the avaiablity of content.

I have always loved the feature, it makes it possible to manage a large photo gallery (camera roll) without feeding up my hard drive. I can decide which photo goes to which category / folder from its thumbnail and a bit of recalling.

Since Windows 10 removed the feature, there has been rumour that the feature will come back in Windows 10 Redstone with a new name, On-Demand Sync. Did I mention Microsoft is the best at renaming? I have not sort my new photos for about one year and a half. Today, I enfin cannot stand this and decided to use OneDrive API (Microsoft Graph API) to make a homemade version of OneDrive sync engine.

## Design and reality

Ideally I am able to implement the placeholder mechanism without using special properties of file systems. I thought that I could store files with name `my_photo.jpg.1drv`, and could register a file handler for `.1drv` to handle everything. I could even write a shell extension to display thumbnails and give proper verbs in the context menu, and download the file on demand. And I can sync everything with `delta` API.

However, time not permitting, I have to finish my job as quickly as possible. So I made a minimum toolchain that is a trade-off between functionality and total time cost (programming + using). It is easily seen that it will take a long time to use the web version of OneDrive to move 1200+ photos, and that it will take a long time to make a sync engine. Moreover, creating a complex sync engine can be error-prone and a defective one is naturally fatal.

Finally I decided to implement the following basic functionalities:

- Request a token and save it;
- Works in the default drive;
- Download the layout of a folder to a folder;
- Files with thumbnails are saved as images, and files without one will be saved as a link that goes to the web page;
- Files and folders are named by their IDs, and the display name is controlled by `desktop.ini`;
- After the user has moved some files, it is possible to synchronise the moving to OneDrive;
- Create OneDrive folders.

## Cmdlets

### `Assert-NoOneDriveError`

A simple cmdlet that ensures the response from an endpoint is not `Error` object.

### `Request-OneDriveToken`

It gets the app ID as the input, which one can easily create one according to [this documentation](https://dev.onedrive.com/app-registration.htm).

It assumes the app allows implicit flow (token flow) and uses [https://login.live.com/oauth20_desktop.srf](https://login.live.com/oauth20_desktop.srf) as the redirect URI.

It works by opening the authentication page in the default browser and waits for the user to feed the final URI of the page. To make it more convenient, one can simply copy the URI and press enter in the host, which means the script should extract the token from the clipboard.

The token should be saved for further use and is valid for an hour.

### `Get-OneDriveItem`

Gets the item entity of an OneDrive item, addressed by ID, special folder name or path.

This cmdlet can be used to navigate in OneDrive. However, this functionality is not so useful and the cmdlet is mostly called from other cmdlets.

### `Get-OneDriveChildren`

Gets the children (either files or folders) of an OneDrive item, addressed by ID, special folder name or path.

This cmdlet returns the thumbnail information and can be used to navigate in OneDrive. However, this functionality is not so useful and the cmdlet is mostly called from other cmdlets.

### `Download-OneDriveLayout`

The set-up cmdlet for the whole sorting-the-photos thing.

Addressed by its ID, the folder’s metadata are downloaded, and its children are downloaded recursively.

If a file has a thumbnail, the file’s placeholder is called `<id>.jpg`; otherwise, it is `<id>.vbs`. A folder is always named `<id>`. Moreover, `desktop.ini` will be present for each folder so that we can deal with file names in File Explorer.

However, the tool uses `desktop.ini` in an abusive way, and once the file is moved, `desktop.ini` will be changed in a way such that the file name is no longer displayed. This can be fixed be calling `Reset-OneDriveMess` cmdlet.

The cmdlet can take a long time to finish, therefore is designed to be interruptable. Should an error occur, one can press Ctrl+C to terminate the command and run `Reset-OneDriveMess` to set the system to a state under which further invocations are likely to succeed.

### `Reset-OneDriveMess`

Most cmdlets here uses `Push-Location` and `Pop-Location` intensively to manage recursion on file system and if the process is interrupted in the middle, it is necessary to go back to the root location and clean all intermediate states.

The cmdlets does the following:

- Pops the location for 100 times;
- Fixes `desktop.ini`;
- Waits 5 seconds for the BITS transfer jobs to terminate.

You should always manually check BITS transfer job after invoking `Reset-OneDriveMess`.

### `New-OneDriveFolder`

Creates a new folder on OneDrive and put it locally.

It is okay to create folders one by one, but sometimes we want to create the whole tree and build them remotely in one shot.

### `Publish-OneDriveFolderLayout`

Recursively finds all new local directories under the current working directory, creates appropriate folders in OneDrive, and finally link the local folders to OneDrive folders.

It is worth noticing that this cmdlet does not do file synching!

### `Complete-MovingOnOneDrive`

If a file or a folder is moved locally and one wish the change is reflected in his OneDrive, he should invoke this cmdlet with the full path of the locally moved item.

## Example

1. Create a new app. Let’s say its app ID is `123456789`.
2. Open “My Documents”, and create a new folder, say `onedrive-playground`.
3. **Open PowerShell in** `onedrive-playground` and import all the cmdlets. It is recommended that you not push any locations before invoking the cmdlets.
4. Invoke `$token = Request-OneDriveToken -AppId '123456789'`.
5. Authenticate yourself in the new web page and authorize the app, then copy the URI in the address bar when you reach the blank page.
6. Return to PowerShell and press Enter.
7. Go to [onedrive.com](https://onedrive.com) and find your favourite folder, take its ID, say `ABCDEF!999`.
8. Return to PowerShell and invoke `Download-OneDriveLayout -AccessToken $token -RootId 'ABCDEF!999'` and wait.
9. If the command encounters a problem, terminate it, invoke `Reset-OneDriveMess` and fix the problem and try again.
10. When the command completes, invoke `Invoke-Item .` to open the current folder in Explorer.
11. You will see the files.

## Example (cont.)

1. Keep yourself in the previous PowerShell session, type `Set-Location ` and press Tab.
2. The auto-complete should give you the real name of your folder, then press Enter.
3. Invoke `New-OneDriveFolder -AccessToken $token -Name 'My New Folder'`.
4. Check OneDrive and the local copy.
5. Now Invoke `md 1, 2; cd 1; md 3, 4; cd 3; md 5; cd ../..;`.
6. Move some files into the newly created folders.
7. Invoke `Publish-OneDriveFolderLayout`. (Do **not** invoke `Reset-OneDriveMess` at this time!)
8. Check OneDrive and the local copy. The local copy should contain some files that display their IDs instead of their name.
9. Invoke `Get-ChildItem desktop.ini -Force -File -Recurse | Select-String '@'`.
10. You will see the moved files with `<id>.xxx=@...,0`.
11. Extract them so that you know which files to move, say you have saved the file names in `$files` variable, so `$files` contains several strings, each of which looks like `C:\Users\Gee\Documents\onedrive-playground\ABCDEF!999\ABCDEF!1024\ABCDEF!524.xxx`.
12. Invoke `Complete-MovingOnOneDrive -AccessToken $token -Files $files`.
13. Check OneDrive and the local copy.
13. Invoke `Reset-OneDriveMess` and check the local copy. The files should be displaying their names, if the cache of Explorer is purged.

## Remarks

I personally organise my camera roll by year and theme/event. So it is quite easy to create two folders saying `2016` and `2017`, create subfolders in them, then move the folders from the `cameraroll` special folder to the appropriate subfolders, and finally invoke `Publish-OneDriveFolderLayout` for the two folders, plus `Complete-MovingOnOneDrive` for all files, recursively in the folders, except `desktop.ini`. It was almost as fast as using the Windows 8.1 sync engine and the thumbnail worked well.

It is not possible to remove/upload/update files with these tools. The only thing you can do is to create new folders and move files around.

I have not thoroughly tested the tool and you should be clear of the risk before invoking the cmdlets. It is suspected to be fatal if the folder contains a folder from another user (shared folder added to OneDrive). So avoid using it with shared folders. Also, you should try it in a sandbox account first.

To resync, recursively remove all `desktop.ini` files and invoke `Download-OneDriveLayout` on the root folder. Then remove any file that does not show up in the `desktop.ini` of the folder that the file is in, and any folders that does not contain a `desktop.ini`.

You are welcome to read the code and find bugs. I will not fix it, unless Microsoft decides not to give On-Demand Sync a comeback in the near future.

## License (MIT)

Copyright © 2017 Gee Law

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
