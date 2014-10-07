## Build From Corpus Script

The script in this directory of the repository is a purpose built script which is meant to be the beginnings of a computational linguistics exercise that semi-automatically builds a `synonym.txt` file from a large corpus of documents. The script is not perfect; it is, however, usable.

## Overview

There are three steps required to process a large corpus of text into a useable synonyms file.

**Step One** parses the text into word counts and into parts of speech arcs. The script uses Ruby's primary natural language processing (NLP) library, [Treat](https://github.com/louismullie/treat) to parse text into its parts of speech. The script, in step one, is given a directory of text files. It reads the files one by one, extracts out the stop words, counts all the words, then chunks the text into trigrams which are then processed using Treat. These results are written out to text files in a created `results` directory of the directory of text files which is provided to the script in step one.

**Step Two** calculates the dice coefficient of the top 4000 words (by word count) in the arcs database and writes the results into a `sim` table in the database.

**Step Three** queries the sim table to find all word pairs about a given dice coefficient and writes those to a `synonyms.txt` file.

Each of these three steps takes a great deal of time to process using the script as it is currently set up.

## Installation

To use this script, Ruby and PostgresDB are required. When ruby is installed, clone this repository.

Install the required dependencies using:

```bash
bundle install
```

After running `bundle install`, an additional -- and rather unusual -- step is required. From the terminal perform the following commands in order:

```bash
irb
```

```ruby
require 'treat'
Treat::Core::Installer.install 'english'
exit
```

The `Treat::Core::Installer.install` command will take a while to complete. Once you exit from the irb session you will need to perform one more step, which is to place the Stanford Core NLP JARs into the right Gem directory. Follow the directions in the [Treat Manual](https://github.com/louismullie/treat/wiki/Manual#download-jars-and-models) to complete this process. This may or may not be taken care of by the install function.

## Usage

Before using the script you will need to set your `JAVA_HOME` environmental variable. If you are on Ubuntu that is easily done by typing the following from the command line:

```bash
export JAVA_HOME=/usr/lib/jvm/java-7-oracle
```

Then you are ready to begin stepping through your corpus of documents.

To run step one on your corpus, type the following command:

```bash
ruby ./build_dict.rb --step-one {{DIRECTORY}} {{POSTGRES_USER}}:{{POSTGRES_PASS}}
```

Before running the command make sure that you have the JAVA_HOME environmental variable set as well as the Redis server running.

To run step two on your corpus, type the following command:

```bash
ruby ./build_dict.rb --step-two {{DIRECTORY}} {{POSTGRES_USER}}:{{POSTGRES_PASS}}
```

Before running the command make sure that your postgres has a database named `legalsyn` and you have created an appropriate username and password for the script to access the database. The user should have sufficient rights to create tables and add and delete data to the tables in order for the script to run properly.

To run step three on your corpus, type the following command:

```bash
ruby ./build_dict.rb --step-three {{MIN_DICE_COEFFICIENT}} {{OUTPUT_SYN_FILE}} {{POSTGRES_USER}}:{{POSTGRES_PASS}}
```

If you wish to run the whole process (which, be forewarned, could take weeks) then type the following command:

```bash
ruby ./build_dict.rb --all-steps {{DIRECTORY}} {{MIN_DICE_COEFFICIENT}} {{OUTPUT_SYN_FILE}} {{POSTGRES_USER}}:{{POSTGRES_PASS}}
```

## Challenges

There are a couple of areas where the script could use work. If you are a computational linguist please do help as we would love some assistance.

* Step One could be modified slightly to use a different chunking algorithm. The script as it currently is situated uses a stop-word-less proximity measurement for chunking the full text into parseable word arcs. These arcs are then parsed according to their parts of speech and their location within the resulting trigram. The trigram is fairly rudimentary in that it is agnostic to paragraph and sentence structure simply using three word chunks from the text. In my testing, it was not efficient, using Treat to parse an entire Title of the US Code while making the NLP level of the stack knowledgeable of sentence and paragraph structure. The parsing overflowed memory even on my 16GB machine many times. Making the Treat layer understand only the chunked trigrams did ease this process significantly.
* Step Two could be modified to use a different coefficient. The Dice Coefficient may not be the best metric for finding similarity in patterns. Indeed, there is a lot of research (some of which is included in the Research Directory of this Repository) and discussions within the computational linguistics space as to how to define the correct similarity coefficient. The Dice Coefficient has been used mostly because it is a common pattern that is fairly well established and modestly easy to code. Now that the script is fully parsing, some effort could be expended toward increasing the effectiveness of the similarity metric used.
* Overall. Speed is a massive issue. This script takes an incredibly long time to complete its various parsing exercises and any assistance on refactoring to increase the speed would be welcome.

## Contributing

1. Fork
2. Hack
3. Pull Request