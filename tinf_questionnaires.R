
library(dplyr)
library(stringr)

tinf_qs <- readxl::read_xlsx("/Users/sarah/Downloads/Tinf.xlsx")

#tinf_selected <- tinf_qs[c("ID", "Sex","Gender", "Race", "Ethnicity", "Age", "")]
selected_qs <- tinf_qs %>% select(
  -StartDate,	-EndDate,	-Status,	-IPAddress,	-Progress,	-'Duration (in seconds)',	
  -Finished,	-RecordedDate,	-ResponseId,	-RecipientLastName,
  -RecipientFirstName,	-RecipientEmail,	-ExternalReference,	-LocationLatitude,
  -LocationLongitude, -DistributionChannel, -`Last Seen Flow Element ID`,	
  -UserLanguage, -Date, -Time, -Experimenters, -`Last Seen Question IDs`)


#Questionnaires included
tinf_qnew <- rename(selected_qs, STAI_Trait_1=STAI_Trait_1...34, 
                  STAI_Trait_2=STAI_Trait_2...35, WHODAS_1=STAI_Trait_1...123, 
                  WHODAS_2=STAI_Trait_2...124, WHODAS_3=Q86_5,	WHODAS_4=Q86_6,	
                  WHODAS_5=Q86_7,	WHODAS_6=Q86_8,	WHODAS_7=Q86_9, WHODAS_8=Q86_10,
                  WHODAS_9=Q86_11, WHODAS_10=Q86_13, WHODAS_11=Q86_14, 
                  WHODAS_12=Q86_16, Diff_days=Q41, Un_active=Q43, Reduce_act=Q44,
                  sleepy=Q45
)


df <- df %>% rename_all(~ str_replace(., "^Q2_", "LSAS_"))

# STAI-Trait Never=0 to almost always = 4: 1, 3, 6, 7, 10, 13, 14, 16, 19 need reverse scoring
STAI <- tinf_qnew %>% select(ID, starts_with('STAI_'))
WHODAS <- tinf_qnew %>% select(ID, starts_with('WHODAS'))
LSAS_anx <- tinf_qnew %>% select(ID, starts_with('Q2_'))


LSAS_avoid <-tinf_qnew %>% select(ID, starts_with('Q3_'))


BDI <-tinf_qnew %>% select(ID, starts_with('BDI_'))

#reverse 1,3,5,9,10,12,14,16,17,19 higher score is worse
PANAS <- tinf_qnew %>% select(ID, starts_with('Q47_'))

#handedness
EHI <- tinf_qnew %>% select(ID, starts_with('Q48_'))

#1 = very true...4=very false for me
# reverse 8, 11, 13, 15?, 16, 19? 24
BISBAS <- tinf_qnew %>% select(ID, starts_with('Q51_'))

#1=rarely, 4 = most/all the time; higher = more negative
# reverse 4, 8, 12, 16
CES_D <- tinf_qnew %>% select(ID, starts_with('Q53_'))

# 1=strongly disagree, 7=strongly agree (higher = more positive)
# reverse code 1,2, 6?, 10?, 14 
BFI_S <- tinf_qnew %>% select(ID, starts_with('Q54_'))
