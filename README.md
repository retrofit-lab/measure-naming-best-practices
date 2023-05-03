# An EEM by any other name: Best practices for naming energy efficiency measures
This repository contains the data and code for the paper "An EEM by Any Other Name: Best Practices for Naming Energy Efficiency Measures", presented at the 2023 ASHRAE Annual Conference in Tampa, FL. 

## Contents  
- [Citation](#citation) 
- [Related Publications](#related-publications)  
- [Repository Structure](#repository-structure)  
- [Objective](#objective)  
- [Data](#data)  
- [Analysis](#analysis)  

## Citation
Khanuja, Apoorv, and Amanda Webb. 2023. “An EEM by Any Other Name: Best Practices for Naming Energy Efficiency Measures.” In *Proceedings of the 2023 ASHRAE Annual Conference*. Tampa, FL.

## Related Publications
- Khanuja, Apoorv, and Amanda L. Webb. 2023. “What We Talk about When We Talk about EEMs: Using Text Mining and Topic Modeling to Understand Building Energy Efficiency Measures (1836-RP).” Science and Technology for the Built Environment 29 (1): 4–18. https://doi.org/10.1080/23744731.2022.2133329.
- [1836-RP FINAL REPORT]

## Repository Structure
The repository is divided into three directories:
- `/data/`: List of measure names to analyze and supporting datasets.  
- `/analysis/`: R script analyzing the measure names
- `/results/`: Output produced by R script

## Objective
The goal of this study was twofold: first, to develop a set of best practices for naming energy efficiency measures (EEMs), and second, to demonstrate a methodology for evaluating a set of measure names using these best practices. There is currently no standard approach for naming energy efficiency measures (EEMs), making it difficult to communicate the intent and scope of an EEM clearly and consistently, and to perform an apples-to-apples comparison of EEM effectiveness across different programs and use cases. 

The best practices (and corresponding common errors) and evaluation methodology developed in this project were applied to a set of EEM names from [ASHRAE 1836-RP](https://www.techstreet.com/ashrae/standards/rp-1836-developing-a-standardized-categorization-system-for-energy-efficiency-measures?product_id=2255440) (ASHRAE members can access for free from the [ASHRAE Technology Portal](https://www.ashrae.org/technical-resources/technology-portal)), as well as a set of draft water conservation measures (WCMs) intended for use in [BuildingSync](https://buildingsync.net/). The application to WCMs highlights how this methodology can be used for types of measures other than energy.  

## Data
There are two types of data associated with this project: (1) a list of measure names to analyze (2) supporting data. 

### Measure names
This evaluation methodology was applied to two sets of measure names.  
- The file [sample-eems.csv](data/sample-eems.csv) contains a random sample of 5% of the EEMs from the ASHRAE 1836-RP main list of EEMs. This list was used to evaluate the [ASHRAE 1836-RP standardized categorization system](https://github.com/retrofit-lab/ashrae-1836-rp-categorization). 
- The file [nrel-wcms-draft.csv](data/nrel-wcms-draft.csv) contains a list of draft WCM names that were provided to the authors by the National Renewable Energy Lab and are intended for use in [BuildingSync](https://buildingsync.net/). 

The measure name files contain five variables (use these headers if you want to analyze your own list of measure names): 
- `eem_id`: A unique ID assigned to each measure in the list.
- `document` : An alphanumeric abbreviation code 3-6 characters in length representing the name of the original source document from which the measure was collected.
- `cat_lev1`: The name of the Level 1 category (i.e., highest level) under which the measure was categorized in the original source document.
- `cat_lev2`: The name of the Level 2 category (i.e., subcategory, if present), under which the measure was categorized in the original source document.  If a Level 2 category was not present, the value of this variable can be coded as “0” or left blank. 
- `eem_name`: The name of the measure as written in the original source document.

### Supporting data
Five supporting data files are used to evaluate the list of measure names for common errors that suggest that the measure name does not follow best practices.  
- The file [tentative-terms.csv](data/tentative-terms.csv) contains a list of verbs that are tentative, and is used to evaluate **Common Error 1: Measure name describes a tentative action or non-action.** This list is a subset of the verbs from the `action-terms.csv`.    
- The file [action-terms.csv](data/action-terms.csv) contains a list of verbs used in measure names in 1836-RP, and is used to evaluate **Common Error 5: Measure name does not contain an action.**  This list was developed from a list of the first words and verbs (as determined by a part-of-speech tagger) in the [ASHRAE 1836-RP main list of EEMs](https://github.com/retrofit-lab/ashrae-1836-rp-text-mining#ashrae-1836-rp-main-list-of-eems). Note that several of these terms could be used as verbs or nouns in a measure name context (e.g., vent, supply). 
- The file [categorization-tags.csv](data/categorization-tags.csv) contains a list of building element terms from the [ASHRAE 1836-RP standardized categorization system] (https://github.com/retrofit-lab/ashrae-1836-rp-categorization), and is used to evaluate **Common Error 6: Measure name does not contain an element.**     
- The file [vague-terms.csv](data/vague-terms.csv) contains a list of terms that are vague but commonly used in the energy efficiency industry, and is used to evaluate **Common Error 7: Measure name uses vague terminology.** This list was developed by reviewing the terms in the [ASHRAE 1836-RP main list of EEMs](https://github.com/retrofit-lab/ashrae-1836-rp-text-mining#ashrae-1836-rp-main-list-of-eems). Terms that imply non-specific performance requirements (e.g., "high efficiency", "optimal") were included in the list of vague terms; terms that imply acceptability (e.g., "adequate", "satisfactory") were not included in the list of vague terms. 
- The file [synonymous-terms.csv](data/synonymous-terms.csv) contains a list of synonymous terms and abbreviations that are commonly used in the energy efficiency industy, and is used to evaluate **Common Error 8: Measure name uses synonymous terminology.** This list was developed by finding synonymous terms and abbreviations in the `categorization-tags.csv` file.  This file contains the following headers:
	- `uni_code`: The UNIFORMAT code that the term is associated with in the `categorization-tags.csv` file.
	- `first_term` : The first of multiple synonymous terms or abbreviations. 
	- `second_term`: The second of multiple synonymous terms or abbreviations. 
	- `third_term`: The third of multiple synonymous terms or abbreviations. 
	- `fourth_term`: The fourth of multiple synonymous terms or abbreviations. 

This list of terms is not exhaustive, but rather serves as an initial starting point that could be expanded in the future.

## Analysis
The R script `measure-name-analysis.R` replicates the analysis from the paper.  The results for the list of WCMs are shown here, as those results are presented in the paper. 

### Setup
It is recommended that you update to the latest versions of both R and RStudio (if using RStudio) prior to running this script. 

#### Load packages
First, load (or install if you do not already have them installed) the packages required for data analysis and plotting. 

```
# Load required packages
library(tidyverse)
library(tidytext)
library(textstem)
```

#### Import list of measure names
Import the list of measure names from the [nrel-wcms-draft.csv](data/nrel-wcms-draft.csv) file.  The relative filepaths in this script follow the same directory structure as this Github repository, and it is recommended that you use this same structure.  You might have to use `setwd()` to set the working directory to the location of the R script.  

```
# Import list of measure names
measure_list <- read_csv("../data/nrel-wcms-draft.csv")
```

### Data pre-processing
Each measure is tokenized into individual words.

```
# Tokenize measure names into single words
tokenized_words <- measure_list %>% 
  unnest_tokens(word, eem_name, drop = FALSE) 
```
This produces a data frame with all of the tokens for each measure. The first 10 lines:

```
   eem_id document cat_lev1                                                     cat_lev2 eem_name                         word       
    <dbl> <lgl>    <chr>                                                        <lgl>    <chr>                            <chr>      
 1      1 NA       AdvancedMeteringSystems and WaterAndSewerConservationSystems NA       Install flow rate meters         install    
 2      1 NA       AdvancedMeteringSystems and WaterAndSewerConservationSystems NA       Install flow rate meters         flow       
 3      1 NA       AdvancedMeteringSystems and WaterAndSewerConservationSystems NA       Install flow rate meters         rate       
 4      1 NA       AdvancedMeteringSystems and WaterAndSewerConservationSystems NA       Install flow rate meters         meters     
 5      2 NA       AlternativeWaterSources                                      NA       Capture condensate               capture    
 6      2 NA       AlternativeWaterSources                                      NA       Capture condensate               condensate 
 7      3 NA       AlternativeWaterSources                                      NA       Reclaim wastewater               reclaim    
 8      3 NA       AlternativeWaterSources                                      NA       Reclaim wastewater               wastewater 
 9      4 NA       AlternativeWaterSources                                      NA       Use atmospheric water generation use        
10      4 NA       AlternativeWaterSources                                      NA       Use atmospheric water generation atmospheric
```

### Analysis and Results
The methodology has four steps: (1) find the frequency distribution of measure length (2) find the most frequently used verbs; (3) find the most frequently used words and bigrams; (4) find the frequency of occurrence of common errors.

#### Measure length 
The number of tokens in each measure name is counted.

```
# Count tokens in each measure name
token_count <- tokenized_words %>% 
  group_by(eem_name) %>% 
  count()
```

These counts are used to compute the minimum, average, median, and maximum number of tokens per measure. 

```
  Minimum Average Median Maximum
    <int>   <dbl>  <dbl>   <int>
1       2     8.1      8      20
```

The distribution is plotted as a histogram:

![Frequency distribution of measure length.](/results/figure-1.png)

#### Most frequently used verbs 
The first word of each measure name is extracted, on the assumption that the first word is most likely to contain the principal verb. 

```
# Extract first word in each measure name
first_word <- tokenized_words %>% 
  group_by(cat_lev1, eem_name) %>% 
  slice_head(n = 1)
```
 
 The frequency of occurrence of each verb is counted and summarized in a table. Counts for the top 30 verbs:
  
|word      |  n|word      |  n|word     |  n|
|:---------|--:|:---------|--:|:--------|--:|
|install   | 40|hire      |  4|evaluate |  2|
|use       | 25|adjust    |  3|inspect  |  2|
|replace   | 22|consider  |  3|monitor  |  2|
|implement | 18|encourage |  3|optimize |  2|
|check     |  8|remove    |  3|recycle  |  2|
|repair    |  8|calibrate |  2|retrofit |  2|
|ensure    |  7|chose     |  2|review   |  2|
|add       |  6|clean     |  2|run      |  2|
|eliminate |  4|create    |  2|test     |  2|
|establish |  4|educate   |  2|aerate   |  1|
 
#### Most frequently used words and bigrams 
Stopwords, which are frequently occurring but uninformative words, are removed from the tokenized measure names using the "snowball" lexicon from the `stopwords` R package.  

```
# Remove stop words from EEMs
tokenized_minus_stopwords <- tokenized_words %>% 
  filter(!(word %in% stopwords::stopwords(source = "snowball")))
```

For reference, the list of stopwords being removed from each EEM is then provided. The first 10 lines:

```
   eem_id document cat_lev1                cat_lev2 eem_name                                                     word 
    <dbl> <lgl>    <chr>                   <lgl>    <chr>                                                        <chr>
 1      7 NA       AlternativeWaterSources NA       Use blowdown water for irrigation                            for  
 2      9 NA       AlternativeWaterSources NA       Use discharged water from water purification processes       from 
 3     14 NA       BoilerPlantImprovements NA       Blowdown accumulated dissolved solids and/or sludge          and  
 4     14 NA       BoilerPlantImprovements NA       Blowdown accumulated dissolved solids and/or sludge          or   
 5     16 NA       BoilerPlantImprovements NA       Implement condensate pump inspection and maintenance program and  
 6     17 NA       BoilerPlantImprovements NA       Implement leak inspection and maintenance program            and  
 7     19 NA       BoilerPlantImprovements NA       Inspect and fire side of boiler                              and  
 8     19 NA       BoilerPlantImprovements NA       Inspect and fire side of boiler                              of   
 9     20 NA       BoilerPlantImprovements NA       Install and maintain condensate return system                and  
10     24 NA       BoilerPlantImprovements NA       Install meters on make-up lines                              on   
```

The list of tokenized measure names without stopwords is then used to find the most frequently occurring words.  The top 10 words in this list:

```
   word          n
   <chr>     <int>
 1 water        64
 2 install      41
 3 replace      32
 4 use          32
 5 equipment    30
 6 system       30
 7 cooling      25
 8 implement    18
 9 flow         17
10 systems      16
```

The process for finding the top bigrams is similar, except that the measure names are tokenized as bigrams instead of words:
	   
```
# Tokenize measures as bigrams
bigram_tokens <- measure_list %>% 
  unnest_tokens(bigram, eem_name, 
                drop = FALSE, 
                stopwords = stopwords::stopwords(source = "snowball"), 
                token = "ngrams", n = 2)
```	   

The top 10 bigrams in this list:

```
   bigram                 n
   <chr>              <int>
 1 cooling tower         15
 2 pass cooling           9
 3 single pass            9
 4 tower management       9
 5 vehicle washing        9
 6 laundry equipment      7
 7 leak detection         7
 8 repair leaks           7
 9 repair replace         7
10 water purification     7
```	   

#### Frequency of common errors
Each measure is evaluated against the common errors using a set of rules. For most of the common errors, this involves a string searching process to look for terms associated with each common error. The script flags the measure with a 1 if the error is present, and 0 if the error is not present. **Common Error 2: Measure name describes the result, rather than the action** is not evaluated in the script, and must be evaulated manually.   

As an example, for Common Error 1, the list of tentative action terms is imported from the [tentative-terms.csv](data/tentative-terms.csv) file. If any of these tentative action terms is found in a measure name, the measure is flagged with a 1 in the new column `Error_1` appended to the `measure_list`. 
	   
```
# Import list of tentative verbs to search for
tentative_terms <- read_csv("../data/tentative-terms.csv")

# Search for and tag measure names that contain tentative verbs
measure_list$Error_1 <- ifelse(grepl(paste0("\\b(", paste(tentative_terms$terms, collapse = "|"), ")\\b"), 
                                     measure_list$eem_name, ignore.case = T), 1, 0)
```	   
	   
After all common errors have been evaluated, the `measure_list` contains seven additional columns indicating whether that error is present in a measure. The first 10 lines:
	  
```
   eem_id document cat_lev1                               cat_lev2 eem_name Error_1 Error_3 Error_4 Error_5 Error_6 Error_7 Error_8
    <dbl> <lgl>    <chr>                                  <lgl>    <chr>      <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>   <dbl>
 1      1 NA       AdvancedMeteringSystems and WaterAndS… NA       Install…       0       0       0       0       0       0       0
 2      2 NA       AlternativeWaterSources                NA       Capture…       0       0       0       0       1       0       0
 3      3 NA       AlternativeWaterSources                NA       Reclaim…       0       0       0       0       1       0       0
 4      4 NA       AlternativeWaterSources                NA       Use atm…       0       0       0       0       1       0       0
 5      5 NA       AlternativeWaterSources                NA       Establi…       0       0       0       1       1       1       0
 6      6 NA       AlternativeWaterSources                NA       Install…       0       0       0       0       1       0       0
 7      7 NA       AlternativeWaterSources                NA       Use blo…       0       0       0       0       1       0       0
 8      8 NA       AlternativeWaterSources                NA       Use des…       0       0       0       0       1       0       0
 9      9 NA       AlternativeWaterSources                NA       Use dis…       0       0       0       0       1       0       0
10     10 NA       AlternativeWaterSources                NA       Use fou…       0       0       0       0       1       0       0
```

The results are then summarized as the total number of errors for each category of measures:

```
   cat_lev1                   total_eems error1_count error3_count error4_count error5_count error6_count error7_count error8_count
   <chr>                           <int>        <dbl>        <dbl>        <dbl>        <dbl>        <dbl>        <dbl>        <dbl>
 1 AdvancedMeteringSystems a…          1            0            0            0            0            0            0            0
 2 AlternativeWaterSources            10            0            0            0            1           10            1            0
 3 BoilerPlantImprovements            17            3            2            1            2           12            1            0
 4 ChilledWaterHotWaterAndSt…          7            0            0            0            0            7            0            0
 5 ChillerPlantImprovements           13            2            1            7            0            0            1            0
 6 InformationAndEducationPr…          7            0            0            1            3            6            1            0
 7 IrrigationSystems                  19            9            1            2            2           17            4            0
 8 KitchenImprovements                28            4            5            8            1           28            4            0
 9 LaboratoryAndMedicalEquip…         28            4            4            8            4           17            4            0
10 LandscapingImprovements            21            7            3            0            4           21            1            0
11 OtherHVAC                          16            6            2            8            0            2            0            0
12 ToiletsAndUrinals                  19            7            3            3            4            2            2            0
13 WashingEquipmentAndTechiq…         18            2            3            2            2           10            0            0
14 WaterAndSewerConservation…         23            6            5            5            3           12            1            0
```
	   
Results for key tables are output as .csv files in the `/results/` directory. 	   
	   
