Poppins fonts

This folder should contain the Poppins font files used by the app. To complete setup:

1. Download the Poppins fonts from Google Fonts: https://fonts.google.com/specimen/Poppins
2. Copy the following files into this folder (example filenames):

   - Poppins-Thin.ttf (weight: 100)
   - Poppins-ExtraLight.ttf (weight: 200)
   - Poppins-Light.ttf (weight: 300)
   - Poppins-Regular.ttf (weight: 400)
   - Poppins-Medium.ttf (weight: 500)
   - Poppins-SemiBold.ttf (weight: 600)
   - Poppins-Bold.ttf (weight: 700)
   - Poppins-ExtraBold.ttf (weight: 800)
   - Poppins-Black.ttf (weight: 900)

3. If you want italics, add the italic files and update `pubspec.yaml` accordingly.

4. Run `flutter pub get` to register the fonts.

Note: The repository includes a `.gitkeep` to ensure the directory exists in version control, but font binaries must be added by you (or downloaded during CI).
