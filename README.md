AddIcon is a small program that lets you add any icon to a
list of files, while also specifying what should be the default
tool for all files that are NOT executable (defaults to 'MultiView').

AddIcon has the following template: FILES/A/M,ICON/A/K,TOOL/K

Ex.
>AddIcon foo.exe foobar.txt barfoo.txt ICON=GFX:Icons/TestIcon TOOL=more

This will add the icon 'GFX:Icons/TestIcon.info' to 'foo.exe',
'foobar.txt' and 'barfoo.txt' and the two textfiles will be given
'More' as a default tool.

PS! The iconname should NOT have a trailing '.info'!
