# CPU frequency applet
A budgie-desktop applet to control the frequency of the processor.
Applet can manage turbo boost and governor. I will add an additional function if requested.

## Dependencies
```
vala
gtk+-3.0 >= 3.18
budgie-1.0 >= 2
glib-2.0 >= 2.46.0
libpeas-1.0 >= 1.8.0
gobject-2.0
polkit-gobject-1
```

### Installing from source
```
meson build --prefix /usr --buildtype=plain
ninja -C build
sudo ninja -C build install
```
