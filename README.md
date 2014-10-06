# Legal-Synonyms

A synonym.txt for Solr Instances. Solr is a great search engine but it is even better with a bit of training. One of the most used ways to train Solr is to add a synonyms.txt file. Building a synonyms.txt file for a particular corpus of language is not an easy exercise. This repository is an attempt to build a synonyms.txt file for a legal corpus so that Solr can be used to search a corpus of documents of a legal nature.

The results of this effort rather than being strictly and traditionally versioned are contained in different synonyms.txt files.

## Theory of this Repository

The general idea of this repository is that any synonyms.txt file which is in the base directory is considered ready while synonyms.txt files which are kept in subdirectories are not yet ready to be used. Once a file is ready it shall be moved to this directory and denoted with the appropriate base from which it was derived.

## Listing of Legal Synonyms.txt

* `synonyms.txt-freeLawProject` is drawn from the [CourtListener repository](https://github.com/freelawproject/courtlistener/blob/master/Solr/conf/lang/synonyms_en.txt) and is licensed GPL according to the terms of the [CourtListener License file](https://github.com/freelawproject/courtlistener/blob/master/LICENSE.txt).
  * **Status**: Ready
* `synonyms.txt-gaoOasis` is drawn from the [1987 Legal Synonyms Document](http://gao.gov/products/OGC-87-6) published by the Government Accountability Office. Synonyms from that document have been OCR'ed, cleaned, and processed into a compatible synonyms.txt file.
  * **Status**: Ready
* `synonyms-uscode-diceX.X.txt` is built from the USCode with a Dice coefficient of X.X (a few have been outputed). Synonyms have been built using the script in the Build From Corpus directory of this repository.
  * **Status**: Semi-Ready

# Usage

Save the `synonyms.txt-...` file which is most suitable to your project to the correct location which has been referenced in your Solr config file. When saving the file, the name should be changed to `synonyms.txt` or else you must update your Solr config files to reference the correct filename.

# Contributing

1. Fork
2. Hack
3. Pull Request

# License

All works within any directories labeled Research or the like are licensed and copyrighted to their authors and are hosted here only as relevant background material which has informed the work herein undertaken.

See LICENSE file for all other terms and conditions with respect to the remainder of the work in this repository.