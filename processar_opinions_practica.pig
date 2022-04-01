REGISTER /usr/lib/pig/piggybank.jar;
extract_details = LOAD '/user/cloudera/pig_analisis_opinions/critiquescinematografiques.csv' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE')  AS (text:chararray, label:int, id:int);
tokens = foreach extract_details generate id,label,text, FLATTEN(TOKENIZE(text)) As word;
dictionary = load '/user/cloudera/pig_analisis_opinions/AFINN.txt' using PigStorage('\t') AS(word:chararray,rating:int);
word_rating = join tokens by word left outer, dictionary by word using 'replicated';
describe word_rating;
rating = foreach word_rating generate tokens::id as id,tokens::text as text, tokens::label as label, dictionary::rating as rate;
word_group = group rating by (id,text,label);
avg_rate = foreach word_group generate group, AVG(rating.rate) as AVG;
comp3 = foreach avg_rate generate group, ((AVG>0)? 1 : 0) as avg_positiu:int, AVG;
/* dump comp3; */
comp4 = foreach avg_rate generate group, ((group.label==0)? 1 : 0) as no_label:int, AVG;
/* dump comp4; */
comp5 = foreach avg_rate generate group, (((AVG>=0) AND (group.label==1)) OR ((AVG<0) AND (group.label==0))? 1 : 0) as c:int, AVG;
comp5 = foreach avg_rate generate group, (((AVG>=0) AND (group.label==1)) OR ((AVG<0) AND (group.label==0))? 1 : NULL) as c:int, AVG;
comp5 = foreach avg_rate generate group, (((AVG>=0) AND (group.label==1)) OR ((AVG<0) AND (group.label==0))? true : false) as c:boolean, AVG;
/* dump comp5; */
