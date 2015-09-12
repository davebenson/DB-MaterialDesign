#! /bin/sh

cat DavebMaterialDesign.swift.preamble

grep -v "<" md.tabsep | perl svgd-to-cgpath.pl

cat DavebMaterialDesign.swift.postamble
