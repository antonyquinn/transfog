lib=../../lib
file=../../web/transfog-reference.gff
CLASSPATH=$lib/biojava.jar:$lib/bytecode.jar:$lib/junit.jar:demos.jar
java -classpath $CLASSPATH gff.GFFFilter --infile $file