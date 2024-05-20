
<!--#echo json="package.json" key="name" underline="=" -->
ubborg-make-example-live-isos-pmb
=================================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Make live ISOs for some example usecases.
<!--/#echo -->



Terminology
-----------

* __oven__:
  The machine that bakes the ISO.
* __bread__:
  The temporary chroot environment in which we install the Ubuntu that will
  later be ISO-ified.



Usage
-----

Just invoke the relevant GitHub Actions workflows.



VirtualBox bugs
---------------

* [Mouse cursor is invisible in the guest OS?](https://superuser.com/a/694155)
  While the VM is off, change the mouse type between PS/2 and USB tablet.
  Or try toggling "Machine &rarr; Disabling Mouse Integration" twice.





Web links
---------

* [Ubuntu minimal](https://wiki.ubuntu.com/Minimal):
  [noble](http://cloud-images.ubuntu.com/minimal/releases/noble/release/)
* [Ubuntu Wiki: Live CD Customization From Scratch
  ](https://help.ubuntu.com/community/LiveCDCustomizationFromScratch)
* [Tutorial: Build your own custom live Ubuntu from scratch
  ](https://github.com/mvallim/live-custom-ubuntu-from-scratch)



<!--#toc stop="scan" -->



&nbsp;


License
-------

<!--#echo json="package.json" key=".license" -->
ISC
<!--/#echo -->

* ⚠ The license is meant for files in this repo. The ISO files created
  contain third-party content for which other licenses do apply.







