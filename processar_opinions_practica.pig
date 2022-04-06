REGISTER /usr/lib/pig/piggybank.jar;
extract_details = LOAD '/user/cloudera/pig_analisis_opinions_practica/critiquescinematografiques.csv'
USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE')  AS (text:chararray, label:int, id:int);
tokens = foreach extract_details generate id,label,text, FLATTEN(TOKENIZE(text)) As word;
dictionary = load '/user/cloudera/pig_analisis_opinions_practica/AFINN.txt' using PigStorage('\t') AS(word:chararray,rating:int);
word_rating = join tokens by word left outer, dictionary by word using 'replicated';
describe word_rating;
rating = foreach word_rating generate tokens::id as id,tokens::text as text, tokens::label as label, dictionary::rating as rate;
word_group = group rating by (id,text,label);
avg_rate = foreach word_group generate group, AVG(rating.rate) as AVG;

comp5 = foreach avg_rate generate group, (((AVG>=0) AND (group.label==1)) OR ((AVG<0) AND (group.label==0))? 1 : 0) as c:int, AVG;
/* dump comp5; */
STORE comp5 INTO '/user/cloudera/WorkspacePigPractica/resultat_analisis_opinions' 
 USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE');

comp5_group = GROUP comp5 ALL;

records_each = FOREACH comp5_group 
                   {
                      trues = FILTER comp5 BY c == 1;
                      falses = FILTER comp5 BY c == 0;
                    GENERATE COUNT(trues) as trues, COUNT(falses) as falses;
                   };
STORE records_each INTO '/user/cloudera/WorkspacePigPractica/resultat_analisis_opinions_count' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE');

rating_count= foreach word_group
  {
      positives = FILTER rating BY rate >= 0;
      negatives = FILTER rating BY rate < 0;
      GENERATE group, COUNT(positives) as n_positives, COUNT(negatives) as n_negatives;
  }
rating_nogroup = foreach rating_count generate group.id, group.text, group.label, n_positives, n_negatives;
comp5_nogroup = foreach comp5 generate group.id, group.text, group.label, c;

rating_join = join comp5_nogroup by (id, text, label) left outer, rating_nogroup by (id, text, label) using 'replicated';
rating_final = foreach rating_join generate comp5_nogroup::id as id, comp5_nogroup::text as text, comp5_nogroup::label as label, comp5_nogroup::c as c, rating_nogroup::n_positives as n_positives, rating_nogroup::n_negatives as n_negatives;
STORE rating_final INTO '/user/cloudera/WorkspacePigPractica/resultat_analisis_opinions_words' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE');
