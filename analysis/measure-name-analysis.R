## -----------------------------------------------------------------------------------------------
## Title: measure-name-analysis.R
## Purpose: Replicates analysis and results
## Paper: "An EEM by Any Other Name: Best Practices for Naming Energy Efficiency Measures"
## Author: Apoorv Khanuja and Amanda Webb
## Date: April 24, 2023
## -----------------------------------------------------------------------------------------------

## Setup

# Load required packages
library(tidyverse)
library(tidytext)
library(textstem)

# Import list of measure names
measure_list <- read_csv("../data/nrel-wcms-draft.csv")
#measure_list <- read_csv("../data/sample-eems.csv")

## Data pre-processing

# Tokenize measure names into single words
tokenized_words <- measure_list %>% 
  unnest_tokens(word, eem_name, drop = FALSE) 

## Analysis and Results

### Find the frequency distribution of measure length

# Count tokens in each measure name
token_count <- tokenized_words %>% 
  group_by(eem_name) %>% 
  count()

# Measure names summary stats
token_count_summary <- tribble(
  ~Minimum, ~Average, ~Median, ~Maximum,
  min(token_count$n), round(mean(token_count$n), 1), round(median(token_count$n), 1), max(token_count$n)
)

# Figure 1: Frequency distribution of word length in measure names
figure_1 <- ggplot(token_count, aes(n)) +
  geom_histogram(binwidth = 1, fill = "light blue") +
  scale_x_continuous(breaks = 2:20, minor_breaks = NULL) +
  scale_y_continuous(breaks = seq(5,40,5), minor_breaks = NULL) +
  xlab("Number of words in the measure") +
  ylab("Number of measures") +
  theme_minimal()

# Save figure to file
ggsave("../results/figure-1.png", bg="white", figure_1, width = 6.49, height = 4.06, units = "in", dpi = 300)

# Table 2: Select and display measures with i words
sample_measures <- token_count %>% 
  group_by(n) %>% 
  slice_head(n=1) %>%
  relocate(eem_name, .after = n)

# Display table in markdown format
knitr::kable(sample_measures)

# Export the table as a CSV file
write_csv(sample_measures, "../results/sample-measures.csv")

### Extract first words to find principal verbs

# Extract first word in each measure name
first_word <- tokenized_words %>% 
  group_by(cat_lev1, eem_name) %>% 
  slice_head(n = 1)

# Frequency of each first word
first_word_counts <- first_word %>% 
  ungroup() %>% 
  count(word) %>% 
  arrange(desc(n))

# Table 3: Frequency distribution of the top 30 first words in measure names
knitr::kable(list(cbind(
  first_word_counts[1:10,], first_word_counts[11:20,], first_word_counts[21:30,])))

# Export the table as a CSV file
write_csv(first_word_counts[1:30,], "../results/top-first-words.csv")

### Find the most frequent words and bigrams

# Remove stop words from measure names
tokenized_minus_stopwords <- tokenized_words %>% 
  filter(!(word %in% stopwords::stopwords(source = "snowball")))

# List of stop words removed from each EEM
removed_stopwords <- tokenized_words %>% 
  filter((word %in% stopwords::stopwords(source = "snowball")))

# List of unique stop words getting removed 
unique_stopwords <- removed_stopwords %>% 
  select(word) %>% 
  unique() %>%
  arrange(word)

# Table 4(a): Top words in measure names 
word_table <- tokenized_minus_stopwords %>% 
  count(word, sort = TRUE) %>% 
  arrange(desc(n)) 

# Export the table as a CSV file
write_csv(word_table, "../results/word-table.csv")

# Tokenize measures as bigrams
bigram_tokens <- measure_list %>% 
  unnest_tokens(bigram, eem_name, 
                drop = FALSE, 
                stopwords = stopwords::stopwords(source = "snowball"), 
                token = "ngrams", n = 2)

# Table 4(b): Top bigrams in measure names 
bigram_table <- bigram_tokens %>% 
  count(bigram, sort = TRUE) %>% 
  arrange(desc(n)) 

# Export the table as a CSV file
write_csv(bigram_table, "../results/bigram-table.csv")

### Evaluate measures for common errors

# Common Error 1: Measure name describes a tentative action or a non-action

# Import list of tentative verbs to search for
tentative_terms <- read_csv("../data/tentative-terms.csv")

# Search for and tag measure names that contain tentative verbs
measure_list$Error_1 <- ifelse(grepl(paste0("\\b(", paste(tentative_terms$terms, collapse = "|"), ")\\b"), 
                                     measure_list$eem_name, ignore.case = T), 1, 0)

# Common Error 2: Measure name describes the end result, rather than the action needed to achieve the result.
# No code for this. Find manually.  

# Common Error 3: Measure name describes multiple actions, rather than a single action.

# Import list of action terms to search for
action_terms <- read_csv("../data/action-terms.csv")

# Search for and tag measure names that contain and/or plus at least two of the action terms 
measure_list$Error_3 <- ifelse(
  grepl(paste0("\\b(", paste(c("and", "or", "and/or"), collapse = "|"), ")\\b", "|;"), measure_list$eem_name, ignore.case = T) &
  str_count(measure_list$eem_name, regex(paste0("\\b(", paste(action_terms$terms, collapse = "|"), ")\\b(?!-)"), ignore_case = TRUE)) >= 2,    
  1, 0)

# Common Error 4: Measure name is excessively long.

# Define a threshold for excessive length
length_threshold <- 10 # 75th percentile length from 1836-RP

# Search for and tag measure names that exceed the length threshold
measure_list$Error_4 <- ifelse(str_count(measure_list$eem_name, "\\S+") > length_threshold, 1, 0)

# Common Error 5: Measure name does not start with an action.

# Search for and tag measure names that do not start with an action term 
measure_list$Error_5 <- ifelse(grepl(paste("^", action_terms$terms, "\\b", collapse = "|", sep=""), 
                                         measure_list$eem_name, ignore.case = T), 0, 1)

# Common Error 6: Measure name does not contain an element.

# Import list of element terms to search for
element_terms <- read_csv("../data/categorization-tags.csv") %>% filter(type == "Element") %>% select(keyword)

# Lemmatize measure name tokens into root form
lemmatized_words <- tokenized_words %>% 
  mutate(word = lemmatize_words(word))

# Paste lemmatized tokens back into measure name
lemmatized_measures <- lemmatized_words %>% 
  group_by(eem_id, document, cat_lev1, cat_lev2, eem_name) %>% 
  summarize(lemmatized_eem_name = paste(word,collapse=" "))

# Search for and tag measure names that contain an element in original, lemmatized, or bigram form 
measure_list$Error_6 <- ifelse(
  grepl(paste0("\\b(", paste(element_terms$keyword, collapse = "|"), ")\\b"), measure_list$eem_name, ignore.case = T) |
  grepl(paste0("\\b(", paste(element_terms$keyword, collapse = "|"), ")\\b"), lemmatized_measures$lemmatized_eem_name, ignore.case = T),
  0, 1)

# Common Error #7: Measure name uses vague terminology.

# Import list of vague terms to search for
vague_terms <- read_csv("../data/vague-terms.csv")

# Search for and tag measure names that contain one of the vague terms
measure_list$Error_7 <- ifelse(grepl(paste0("\\b(", paste(vague_terms$terms, collapse = "|"), ")\\b"), 
                                     measure_list$eem_name, ignore.case = T), 1, 0)

# Common Error #8: Measure names use synonymous terminology.

# Import list of synonymous terms to search for
synonymous_terms <- read_csv("../data/synonymous-terms.csv")

# Turn column of measure names into a single string
names_string <- str_c(measure_list$eem_name, sep = "", collapse = " ")

# Detect occurrences of more than one version of a synonymous term across all measure names
synonymous_terms <- synonymous_terms %>%
  mutate(
    first_term = str_extract(names_string, regex(paste("\\b", first_term, "\\b", sep=""), ignore_case = TRUE)),
    second_term = str_extract(names_string, regex(paste("\\b", second_term, "\\b", sep=""), ignore_case = TRUE)), 
    third_term = str_extract(names_string, regex(paste("\\b", third_term, "\\b", sep=""), ignore_case = TRUE)), 
    fourth_term = str_extract(names_string, regex(paste("\\b", fourth_term, "\\b", sep=""), ignore_case = TRUE))) %>%
  rowwise() %>% 
  mutate(total = sum(!is.na(c_across(first_term:fourth_term)))) %>%  
  filter(total >= 2) %>%
  unite("regex", first_term:fourth_term, sep = "|", na.rm = TRUE, remove = FALSE) 

# Search for and tag measure names that contain one of the synonymous terms
measure_list$Error_8 <- ifelse(
  nrow(synonymous_terms) != 0 &
  grepl(paste0("\\b(", paste(synonymous_terms$regex, collapse = "|"), ")\\b"), measure_list$eem_name, ignore.case = T), 1, 0)

# Export list of measures with error flags as a CSV file
write_csv(measure_list, "../results/measure-list-errors.csv")

# Table 5: Distribution of measures and errors across technology categories
summary_table_errors <- measure_list %>%
  group_by(cat_lev1) %>%
  summarise(total_eems = n(),
            error1_count = sum(Error_1),
            error3_count = sum(Error_3),
            error4_count = sum(Error_4),
            error5_count = sum(Error_5),
            error6_count = sum(Error_6),
            error7_count = sum(Error_7),
            error8_count = sum(Error_8))

# Display table in markdown format
knitr::kable(summary_table_errors)

# Export the table as a CSV file
write_csv(summary_table_errors, "../results/summary-table-errors.csv")
