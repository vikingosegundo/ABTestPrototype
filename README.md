# ABTestPrototype

A simple SDK for A/B testing

When I first saw how Optimizly can change a running app that just has the
SDK included but no other changes to the original source code, it looked like
sorcery to me.  

Later I saw this question on Stack Overflow:

> [How does Apptimize \ Optimizely work on iOS?][1]

and I gave it a go.

This is not a ready to use SDK and probably never will be. But who knows for sure …

----

Instead of creating some sort of network service, that SDK it-self contains a little
server to receive changes.

![change colors via network][2]

[1]: http://stackoverflow.com/questions/29879195/how-does-apptimize-optimizely-work-on-ios/30194771#30194771
[2]: changecolors.gif
