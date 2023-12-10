# GPS Location
Android-App written in flutter / dart to show the current location (lat lon as well as UTM), speed etc. 
as values and on a map. Allows to save waypoints and browse, and you can easily share your position or waypoints.

Uses flutter_map, langlong2, geolocator, proj4dart, among other packages. State is maneged with the 
provider package.

I wrote this App to learn flutter. I am not sharing it on the app store, because I am using the 
main tile server of OpenStreetMap that should not be overwhelmed with requests. 

If you are forking this repro and start to develop for many users, please don't forget to change
"userAgentPackageName: 'com.example.app'" in mapwidget.dart.


