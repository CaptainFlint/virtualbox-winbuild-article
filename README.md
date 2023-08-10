# VirtualBox Building for Windows Instruction

This article describes how to build the Windows version of [VirtualBox](https://www.virtualbox.org/) from source.

The text is written in the form of template, from which the human-readable versions of the article are generated, suitable for publishing. The main platform is habr.com, the article is posted by the following links:
* [Russian](https://habr.com/ru/articles/357526/)
* [English](https://habr.com/ru/articles/447300/)

## Building
To generate the article files, run the make script with optional parameters, specifying which versions of the article you need. The targets are using the format **LNG-TYPE**, where **LNG** is `en` or `ru`, and **TYPE** is either `habr` (to generate the content for posting on Habr and using its specific formatting tags) or `raw` (for generic HTML file which can be opened in a web browser directly).

**Example:**
```
perl make.pl ru-habr ru-raw en-raw
```
If no targets are passed, all the 4 possible formats are generated.
