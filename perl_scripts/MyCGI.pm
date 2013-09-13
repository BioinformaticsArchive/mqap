package MyCGI;
use Carp ;
use POSIX ;
require Exporter;
use FileHandle ;
use Getopt::Long;
#use Math::Trig;
#use Math::Trig ':radial';
no warnings 'redefine';
my $EPSILON = 0.01;

  local $SIG{__WARN__} = sub {};

@ISA = qw(Exporter);
@EXPORT = qw( 
	cgi_PrintLogForCommand cgi_PrintError
	cgi_End cgi_GetTable cgi_SaveFile cgi_FormSearch
	cgi_Start cgi_GetTableUlta cgi_GetTableWithPDBid
	cgi_GetEnv
	    );


use strict ;

my $verbose = 0 ;
my $havetokeepthispostive = 13 ;


sub cgi_PrintError{
   my ($mesg) = @_ ;
   die <<"EOT";
   $mesg 
EOT
}

sub cgi_PrintLogForCommand{
   my ($q,$command) = @_ ;
   my @kk = `$command` ;
   foreach my $k (@kk){
      print $q->p("$k");
   }
}

sub cgi_GetTable{ 
my %tab = ( 
'0ALL' => 'ALL', 
'1B0F' => 'PROTEIN (ELASTASE)', 
'1NPY' => 'Hypothetical shikimate 5-dehydrogenase-like p', 
'1A0J' => 'TRYPSIN', 
'1A4L' => 'ADENOSINE DEAMINASE', 
'1A79' => 'TRNA ENDONUCLEASE', 
'1A7U' => 'CHLOROPEROXIDASE T', 
'1A8H' => 'METHIONYL-TRNA SYNTHETASE', 
'1A8S' => 'CHLOROPEROXIDASE F', 
'1A95' => 'XANTHINE-GUANINE PHOSPHORIBOSYLTRANSFERASE', 
'1AB4' => 'GYRASE A', 
'1AFR' => 'DELTA9 STEAROYL-ACYL CARRIER PROTEIN DESATURA', 
'1AFW' => '3-KETOACETYL-COA THIOLASE', 
'1AGY' => 'CUTINASE', 
'1AJ0' => 'DIHYDROPTEROATE SYNTHASE', 
'1AJ8' => 'CITRATE SYNTHASE', 
'1AKM' => 'ORNITHINE TRANSCARBAMYLASE', 
'1AKO' => 'EXONUCLEASE III', 
'1AL6' => 'CITRATE SYNTHASE', 
'1ALD' => 'ALDOLASE A', 
'1AM2' => 'MXE GYRA INTEIN', 
'1APX' => 'CYTOSOLIC ASCORBATE PEROXIDASE', 
'1AQ0' => '1,3-1,4-BETA-GLUCANASE', 
'1AQ2' => 'PHOSPHOENOLPYRUVATE CARBOXYKINASE', 
'1ASY' => 'ASPARTYL-tRNA SYNTHETASE', 
'1AT1' => 'ASPARTATE CARBAMOYLTRANSFERASE, CATALYTIC CHA', 
'1AUK' => 'ARYLSULFATASE A', 
'1AUO' => 'CARBOXYLESTERASE', 
'1AVF' => 'GASTRICSIN', 
'1AZW' => 'PROLINE IMINOPEPTIDASE', 
'1B2M' => 'RIBONUCLEASE T1', 
'1B57' => 'PROTEIN (FRUCTOSE-BISPHOSPHATE ALDOLASE II)', 
'1B5D' => 'PROTEIN (DEOXYCYTIDYLATE HYDROXYMETHYLASE)', 
'1B6B' => 'PROTEIN (ARYLALKYLAMINE N-ACETYLTRANSFERASE)', 
'1B6G' => 'HALOALKANE DEHALOGENASE', 
'1B6T' => 'PROTEIN (PHOSPHOPANTETHEINE ADENYLYLTRANSFERA', 
'1B73' => 'GLUTAMATE RACEMASE', 
'1B8G' => 'PROTEIN (1-AMINOCYCLOPROPANE-1-CARBOXYLATE SY', 
'1B93' => 'PROTEIN (METHYLGLYOXAL SYNTHASE)', 
'1BBS' => 'RENIN', 
'1BD3' => 'URACIL PHOSPHORIBOSYLTRANSFERASE', 
'1BF2' => 'ISOAMYLASE', 
'1BFD' => 'BENZOYLFORMATE DECARBOXYLASE', 
'1BG0' => 'ARGININE KINASE', 
'1BHG' => 'BETA-GLUCURONIDASE', 
'1BIB' => 'BIR A', 
'1BIX' => 'AP ENDONUCLEASE 1', 
'1BJO' => 'PHOSPHOSERINE AMINOTRANSFERASE', 
'1BMT' => 'METHIONINE SYNTHASE', 
'1BOL' => 'PROTEIN (RIBONUCLEASE RH)', 
'1BOO' => 'PROTEIN (N-4 CYTOSINE-SPECIFIC METHYLTRANSFER', 
'1BP2' => 'PHOSPHOLIPASE A2', 
'1BRM' => 'ASPARTATE-SEMIALDEHYDE DEHYDROGENASE', 
'1BRW' => 'PROTEIN (PYRIMIDINE NUCLEOSIDE PHOSPHORYLASE)', 
'1BS0' => 'PROTEIN (8-AMINO-7-OXONANOATE SYNTHASE)', 
'1BS9' => 'ACETYL XYLAN ESTERASE', 
'1BSJ' => 'PROTEIN (PEPTIDE DEFORMYLASE)', 
'1BTL' => 'BETA-LACTAMASE TEM1', 
'1BVZ' => 'PROTEIN (ALPHA-AMYLASE II)', 
'1BWD' => 'PROTEIN (INOSAMINE-PHOSPHATE AMIDINOTRANSFERA', 
'1BWP' => 'PLATELET-ACTIVATING FACTOR ACETYLHYDROLASE', 
'1BWZ' => 'PROTEIN (DIAMINOPIMELATE EPIMERASE)', 
'1BZC' => 'PROTEIN (PROTEIN-TYROSINE-PHOSPHATASE)', 
'1BZY' => 'HYPOXANTHINE-GUANINE PHOSPHORIBOSYLTRANSFERAS', 
'1C54' => 'RIBONUCLEASE SA', 
'1C82' => 'HYALURONATE LYASE', 
'1CA1' => 'ALPHA-TOXIN', 
'1CBG' => 'CYANOGENIC BETA-GLUCOSIDASE', 
'1CD5' => 'PROTEIN (GLUCOSAMINE 6-PHOSPHATE DEAMINASE)', 
'1CDE' => 'PHOSPHORIBOSYL-GLYCINAMIDE FORMYLTRANSFERASE', 
'1CEL' => '1,4-BETA-D-GLUCAN CELLOBIOHYDROLASE I', 
'1CG2' => 'CARBOXYPEPTIDASE G2', 
'1CGK' => 'PROTEIN (CHALCONE SYNTHASE)', 
'1CHM' => 'CREATINE AMIDINOHYDROLASE', 
'1CMX' => 'PROTEIN (UBIQUITIN YUH1-UBAL)', 
'1CNS' => 'CHITINASE', 
'1COY' => 'CHOLESTEROL OXIDASE', 
'1CTN' => 'CHITINASE A', 
'1CV2' => 'HALOALKANE DEHALOGENASE', 
'1CVR' => 'GINGIPAIN R', 
'1CWY' => 'AMYLOMALTASE', 
'1CZF' => 'POLYGALACTURONASE II', 
'1D2H' => 'GLYCINE N-METHYLTRANSFERASE', 
'1D3G' => 'DIHYDROOROTATE DEHYDROGENASE', 
'1D4A' => 'QUINONE REDUCTASE', 
'1D4C' => 'FLAVOCYTOCHROME C FUMARATE REDUCTASE', 
'1D7R' => 'PROTEIN (2,2-DIALKYLGLYCINE DECARBOXYLASE (PY', 
'1D8C' => 'MALATE SYNTHASE G', 
'1D8H' => 'mRNA TRIPHOSPHATASE CET1', 
'1DAA' => 'D-AMINO ACID AMINOTRANSFERASE', 
'1DAE' => 'DETHIOBIOTIN SYNTHETASE', 
'1DB3' => 'GDP-MANNOSE 4,6-DEHYDRATASE', 
'1DBT' => 'OROTIDINE 5 -PHOSPHATE DECARBOXYLASE', 
'1DD8' => 'BETA-KETOACYL [ACYL CARRIER PROTEIN] SYNTHASE', 
'1DDJ' => 'PLASMINOGEN', 
'1DE3' => 'RIBONUCLEASE ALPHA-SARCIN', 
'1DE6' => 'L-RHAMNOSE ISOMERASE', 
'1DFO' => 'SERINE HYDROXYMETHYLTRANSFERASE', 
'1DGS' => 'DNA LIGASE', 
'1DHP' => 'DIHYDRODIPICOLINATE SYNTHASE', 
'1DHR' => 'DIHYDROPTERIDINE REDUCTASE', 
'1DI1' => 'ARISTOLOCHENE SYNTHASE', 
'1DII' => 'P-CRESOL METHYLHYDROXYLASE', 
'1DIZ' => '3-METHYLADENINE DNA GLYCOSYLASE II', 
'1DJL' => 'TRANSHYDROGENASE DIII', 
'1DL2' => 'CLASS I ALPHA-1,2-MANNOSIDASE', 
'1DLI' => 'UDP-GLUCOSE DEHYDROGENASE', 
'1DNK' => 'PROTEIN (DEOXYRIBONUCLEASE I (DNASE I) (E.C.3', 
'1DNP' => 'DNA PHOTOLYASE', 
'1DPT' => 'D-DOPACHROME TAUTOMERASE', 
'1DUB' => '2-ENOYL-COA HYDRATASE', 
'1DWO' => 'HYDROXYNITRILE LYASE', 
'1E0C' => 'SULFURTRANSFERASE', 
'1E19' => 'CARBAMATE KINASE-LIKE CARBAMOYLPHOSPHATE SYNT', 
'1E1O' => 'LYSYL-TRNA SYNTHETASE', 
'1E2T' => 'N-HYDROXYARYLAMINE O-ACETYLTRANSFERASE', 
'1E7Q' => 'GDP-FUCOSE SYNTHETASE', 
'1EAG' => 'ASPARTIC PROTEINASE (SAP2 GENE PRODUCT)', 
'1EC9' => 'GLUCARATE DEHYDRATASE', 
'1ECF' => 'GLUTAMINE PHOSPHORIBOSYLPYROPHOSPHATE AMIDOTR', 
'1ECL' => 'ESCHERICHIA COLI TOPOISOMERASE I', 
'1EF8' => 'METHYLMALONYL COA DECARBOXYLASE', 
'1EH5' => 'PALMITOYL PROTEIN THIOESTERASE 1', 
'1EH6' => 'O6-ALKYLGUANINE-DNA ALKYLTRANSFERASE', 
'1EHI' => 'D-ALANINE:D-LACTATE LIGASE', 
'1EI5' => 'D-AMINOPEPTIDASE', 
'1EIX' => 'OROTIDINE 5 -MONOPHOSPHATE DECARBOXYLASE', 
'1EO7' => 'PROTEIN (CYCLODEXTRIN GLYCOSYLTRANSFERASE)', 
'1EQ2' => 'ADP-L-GLYCERO-D-MANNOHEPTOSE 6-EPIMERASE', 
'1EUU' => 'SIALIDASE', 
'1EUY' => 'GLUTAMINYL-TRNA SYNTHETASE', 
'1EYI' => 'FRUCTOSE-1,6-BISPHOSPHATASE', 
'1EYP' => 'CHALCONE-FLAVONONE ISOMERASE 1', 
'1F2D' => '1-AMINOCYCLOPROPANE-1-CARBOXYLATE DEAMINASE', 
'1F6D' => 'UDP-N-ACETYLGLUCOSAMINE 2-EPIMERASE', 
'1F75' => 'UNDECAPRENYL PYROPHOSPHATE SYNTHETASE', 
'1F7U' => 'ARGINYL-TRNA SYNTHETASE', 
'1F8M' => 'ISOCITRATE LYASE', 
'1F8X' => 'NUCLEOSIDE 2-DEOXYRIBOSYLTRANSFERASE', 
'1FCB' => 'FLAVOCYTOCHROME B2', 
'1FCQ' => 'HYALURONOGLUCOSAMINIDASE', 
'1FGH' => 'ACONITASE', 
'1FJO' => 'THERMOLYSIN', 
'1FNB' => 'FERREDOXIN-NADP+ REDUCTASE', 
'1FOB' => 'BETA-1,4-GALACTANASE', 
'1FOH' => 'PHENOL HYDROXYLASE', 
'1FY2' => 'ASPARTYL DIPEPTIDASE', 
'1G0D' => 'PROTEIN-GLUTAMINE GAMMA-GLUTAMYLTRANSFERASE', 
'1G6T' => 'EPSP SYNTHASE', 
'1G99' => 'ACETATE KINASE', 
'1GAL' => 'GLUCOSE OXIDASE', 
'1GCB' => 'GAL6 HG (EMTS) DERIVATIVE', 
'1GCU' => 'BILIVERDIN REDUCTASE A', 
'1GDH' => 'D-GLYCERATE DEHYDROGENASE', 
'1GEQ' => 'TRYPTOPHAN SYNTHASE ALPHA-SUBUNIT', 
'1GIM' => 'ADENYLOSUCCINATE SYNTHETASE', 
'1GLO' => 'CATHEPSIN S', 
'1GOG' => 'GALACTOSE OXIDASE', 
'1GOX' => '(S)-2-HYDROXY-ACID OXIDASE, PEROXISOMAL', 
'1GPA' => 'GLYCOGEN PHOSPHORYLASE A', 
'1GPM' => 'GMP SYNTHETASE', 
'1GPR' => 'GLUCOSE PERMEASE', 
'1GQ8' => 'PECTIN METHYLESTERASE', 
'1GSA' => 'GLUTATHIONE SYNTHETASE', 
'1GUM' => 'PROTEIN (GLUTATHIONE TRANSFERASE A4-4)', 
'1H7O' => '5-AMINOLAEVULINIC ACID DEHYDRATASE', 
'1HDH' => 'ARYLSULFATASE', 
'1HPL' => 'LIPASE', 
'1HRK' => 'FERROCHELATASE', 
'1HTI' => 'TRIOSEPHOSPHATE ISOMERASE', 
'1HY3' => 'ESTROGEN SULFOTRANSFERASE', 
'1HZD' => 'AU-BINDING PROTEIN/ENOYL-COA HYDRATASE', 
'1I78' => 'PROTEASE VII', 
'1I8T' => 'UDP-GALACTOPYRANOSE MUTASE', 
'1I9A' => 'ISOPENTENYL-DIPHOSPHATE DELTA-ISOMERASE', 
'1IG8' => 'hexokinase PII', 
'1ILE' => 'ISOLEUCYL-TRNA SYNTHETASE', 
'1IPH' => 'CATALASE HPII', 
'1IU4' => 'microbial transglutaminase', 
'1J49' => 'D-LACTATE DEHYDROGENASE', 
'1JDW' => 'L-ARGININE:GLYCINE AMIDINOTRANSFERASE', 
'1JS4' => 'ENDO/EXOCELLULASE E4', 
'1JXA' => 'glucosamine 6-phosphate synthase', 
'1K4L' => '3,4-Dihydroxy-2-Butanone 4-Phosphate Synthase', 
'1K4T' => 'DNA topoisomerase I', 
'1KAS' => 'BETA-KETOACYL ACP SYNTHASE II', 
'1KEZ' => 'ERYTHRONOLIDE SYNTHASE', 
'1KNP' => 'L-aspartate oxidase', 
'1KZL' => 'Riboflavin Synthase', 
'1L1L' => 'RIBONUCLEOSIDE TRIPHOSPHATE REDUCTASE', 
'1L6P' => 'Thiol:disulfide interchange protein dsbD', 
'1L7D' => 'nicotinamide nucleotide Transhydrogenase, sub', 
'1LDM' => 'M4 LACTATE DEHYDROGENASE', 
'1LI5' => 'CYSTEINYL-TRNA SYNTHETASE', 
'1LJL' => 'arsenate reductase', 
'1LTQ' => 'POLYNUCLEOTIDE KINASE', 
'1LUC' => 'BACTERIAL LUCIFERASE', 
'1M0T' => 'glutathione synthetase', 
'1M9C' => 'Cyclophilin A', 
'1MBB' => 'URIDINE DIPHOSPHO-N-ACETYLENOLPYRUVYLGLUCOSAM', 
'1MDR' => 'MANDELATE RACEMASE', 
'1MEK' => 'PROTEIN DISULFIDE ISOMERASE', 
'1MLA' => 'MALONYL-COENZYME A ACYL CARRIER PROTEIN TRANS', 
'1MPP' => 'PEPSIN', 
'1MPY' => 'CATECHOL 2,3-DIOXYGENASE', 
'1MUC' => 'MUCONATE LACTONIZING ENZYME', 
'1MYR' => 'MYROSINASE', 
'1NAA' => 'Cellobiose dehydrogenase', 
'1NBA' => 'N-CARBAMOYLSARCOSINE AMIDOHYDROLASE', 
'1NBF' => 'Ubiquitin carboxyl-terminal hydrolase 7', 
'1NLN' => 'Adenain', 
'1NLU' => 'SEDOLISIN', 
'1NMW' => 'Peptidyl-prolyl cis-trans isomerase NIMA-inte', 
'1NN4' => 'Ribose 5-phosphate isomerase B', 
'1NSF' => 'N-ETHYLMALEIMIDE SENSITIVE FACTOR', 
'1NWW' => 'Limonene-1,2-epoxide hydrolase', 
'1OBA' => 'LYSOZYME', 
'1OG1' => 'T-CELL ECTO-ADP-RIBOSYLTRANSFERASE 2', 
'1OH9' => 'ACETYLGLUTAMATE KINASE', 
'1ONR' => 'TRANSALDOLASE B', 
'1OQZ' => 'glutaryl acylase', 
'1ORD' => 'ORNITHINE DECARBOXYLASE', 
'1OTG' => '5-CARBOXYMETHYL-2-HYDROXYMUCONATE ISOMERASE', 
'1OYA' => 'OLD YELLOW ENZYME', 
'1OYG' => 'levansucrase', 
'1P1X' => 'Deoxyribose-phosphate aldolase', 
'1P7M' => 'DNA-3-methyladenine glycosylase I', 
'1PA9' => 'Protein-tyrosine phosphatase yopH', 
'1PAD' => 'PAPAIN', 
'1PFK' => 'PHOSPHOFRUCTOKINASE', 
'1PFQ' => 'Dipeptidyl peptidase IV soluble form', 
'1PJH' => 'enoyl-CoA isomerase; Eci1p', 
'1PKN' => 'PYRUVATE KINASE', 
'1PMI' => 'PHOSPHOMANNOSE ISOMERASE', 
'1PO5' => 'Cytochrome P450 2B4', 
'1POW' => 'PYRUVATE OXIDASE', 
'1PTD' => 'PHOSPHATIDYLINOSITOL-SPECIFIC PHOSPHOLIPASE C', 
'1PVD' => 'PYRUVATE DECARBOXYLASE', 
'1PYM' => 'PROTEIN (PHOSPHOENOLPYRUVATE MUTASE)', 
'1Q6L' => '3-keto-L-gulonate 6-phosphate decarboxylase', 
'1QAM' => 'ERMC  METHYLTRANSFERASE', 
'1QFE' => 'PROTEIN (3-DEHYDROQUINATE DEHYDRATASE)', 
'1QFM' => 'PROTEIN (PROLYL OLIGOPEPTIDASE)', 
'1QGX' => '3 ,5 -ADENOSINE BISPHOSPHATASE', 
'1QHF' => 'PROTEIN (PHOSPHOGLYCERATE MUTASE)', 
'1QHO' => 'ALPHA-AMYLASE', 
'1QK2' => 'CELLOBIOHYDROLASE CEL6A (FORMERLY CALLED CBH ', 
'1QQ5' => 'PROTEIN (L-2-HALOACID DEHALOGENASE)', 
'1QRG' => 'CARBONIC ANHYDRASE', 
'1QRR' => 'sulfolipid biosynthesis (SQD1) PROTEIN', 
'1QTN' => 'CASPASE-8', 
'1QX3' => 'Apopain', 
'1QZ9' => 'KYNURENINASE', 
'1R30' => 'Biotin synthase', 
'1RA2' => 'DIHYDROFOLATE REDUCTASE', 
'1RBA' => 'RUBISCO', 
'1RBL' => 'RIBULOSE 1,5 BISPHOSPHATE CARBOXYLASE/OXYGENA', 
'1RHS' => 'SULFUR-SUBSTITUTED RHODANESE', 
'1RK2' => 'RIBOKINASE', 
'1ROZ' => 'Deoxyhypusine synthase', 
'1RPT' => 'PROSTATIC ACID PHOSPHATASE', 
'1RPX' => 'PROTEIN (RIBULOSE-PHOSPHATE 3-EPIMERASE)', 
'1RTU' => 'RIBONUCLEASE U2', 
'1S95' => 'Serine/threonine protein phosphatase 5', 
'1SCA' => 'SUBTILISIN CARLSBERG', 
'1SES' => 'SERYL-tRNA SYNTHETASE', 
'1SME' => 'PLASMEPSIN II', 
'1SMN' => 'EXTRACELLULAR ENDONUCLEASE', 
'1SNN' => '3,4-dihydroxy-2-butanone 4-phosphate synthase', 
'1STD' => 'SCYTALONE DEHYDRATASE', 
'1T7D' => 'Signal peptidase I', 
'1TDE' => 'THIOREDOXIN REDUCTASE', 
'1THG' => 'LIPASE', 
'1TYS' => 'THYMIDYLATE SYNTHASE', 
'1UAE' => 'UDP-N-ACETYLGLUCOSAMINE ENOLPYRUVYL TRANSFERA', 
'1UAG' => 'UDP-N-ACETYLMURAMOYL-L-ALANINE/:D-GLUTAMATE L', 
'1UCH' => 'UBIQUITIN C-TERMINAL HYDROLASE UCH-L3', 
'1UF7' => 'N-carbamyl-D-amino acid amidohydrolase', 
'1ULA' => 'PURINE NUCLEOSIDE PHOSPHORYLASE', 
'1UOK' => 'OLIGO-1,6-GLUCOSIDASE', 
'1VAO' => 'VANILLYL-ALCOHOL OXIDASE', 
'1VAS' => 'PROTEIN (T4 ENDONUCLEASE V (E.C.3.1.25.1))', 
'1VBN' => 'Tyrosyl-tRNA synthetase', 
'1VCM' => 'CTP synthetase', 
'1VR7' => 'S-adenosylmethionine decarboxylase proenzyme', 
'1VZZ' => 'STEROID DELTA-ISOMERASE', 
'1WD8' => 'Protein-arginine deiminase type IV', 
'1WKB' => 'Leucyl-tRNA synthetase', 
'1XTC' => 'CHOLERA TOXIN', 
'1XYZ' => '1,4-BETA-D-XYLAN-XYLANOHYDROLASE', 
'1YBV' => 'TRIHYDROXYNAPHTHALENE REDUCTASE', 
'1YLU' => 'Oxygen-insensitive NAD(P)H nitroreductase', 
'1YSC' => 'SERINE CARBOXYPEPTIDASE', 
'1Z9H' => 'membrane-associated prostaglandin E synthase-', 
'1ZIO' => 'ADENYLATE KINASE', 
'1ZNB' => 'METALLO-BETA-LACTAMASE', 
'1ZRZ' => 'Protein kinase C, iota', 
'2AAT' => 'ASPARTATE AMINOTRANSFERASE', 
'2ACE' => 'ACETYLCHOLINESTERASE', 
'2ACU' => 'ALDOSE REDUCTASE', 
'2ADM' => 'ADENINE-N6-DNA-METHYLTRANSFERASE TAQI', 
'2AMG' => '1,4-ALPHA-D-GLUCAN MALTOTETRAHYDROLASE', 
'2AYH' => '1,3-1,4-BETA-D-GLUCAN 4-GLUCANOHYDROLASE', 
'2BVC' => 'GLUTAMINE SYNTHETASE 1', 
'2CND' => 'NADH-DEPENDENT NITRATE REDUCTASE', 
'2CPU' => 'ALPHA-AMYLASE', 
'2D3A' => 'glutamine synthetase', 
'2DLN' => 'D-ALANINE--D-ALANINE LIGASE', 
'2EJ9' => 'Putative biotin ligase', 
'2ESD' => 'NADP-dependent glyceraldehyde-3-phosphate deh', 
'2F61' => 'Acid beta-glucosidase', 
'2GSA' => 'GLUTAMATE SEMIALDEHYDE AMINOTRANSFERASE', 
'2GVW' => 'Phosphotriesterase', 
'2HGS' => 'PROTEIN (GLUTATHIONE SYNTHETASE)', 
'2ISD' => 'PHOSPHOINOSITIDE-SPECIFIC PHOSPHOLIPASE C, IS', 
'2JXR' => 'PROTEINASE A', 
'2LIP' => 'LIPASE', 
'2LPR' => 'ALPHA-LYTIC PROTEASE', 
'2NAC' => 'NAD-DEPENDENT FORMATE DEHYDROGENASE', 
'2NMT' => 'MYRISTOYL-COA:PROTEIN N-MYRISTOYLTRANSFERASE', 
'2OAT' => 'ORNITHINE AMINOTRANSFERASE', 
'2PFL' => 'PROTEIN (PYRUVATE FORMATE-LYASE)', 
'2PGD' => '6-PHOSPHOGLUCONATE DEHYDROGENASE', 
'2PLC' => 'PHOSPHATIDYLINOSITOL-SPECIFIC PHOSPHOLIPASE C', 
'2PTH' => 'PEPTIDYL-TRNA HYDROLASE', 
'2QMO' => 'Dethiobiotin synthetase', 
'2TDT' => 'TETRAHYDRODIPICOLINATE N-SUCCINYLTRANSFERASE', 
'2TMD' => 'TRIMETHYLAMINE DEHYDROGENASE', 
'2YPN' => 'PROTEIN (HYDROXYMETHYLBILANE SYNTHASE)', 
'3CLA' => 'TYPE III CHLORAMPHENICOL ACETYLTRANSFERASE', 
'3CSM' => 'CHORISMATE MUTASE', 
'3NOS' => 'ENDOTHELIAL NITRIC-OXIDE SYNTHASE', 
'3PVA' => 'PROTEIN (PENICILLIN V ACYLASE)', 
'3R1R' => 'RIBONUCLEOTIDE REDUCTASE R1 PROTEIN', 
'4KBP' => 'PURPLE ACID PHOSPHATASE', 
'4MDH' => 'CYTOPLASMIC MALATE DEHYDROGENASE', 
'5COX' => 'CYCLOOXYGENASE-2', 
'5CPA' => 'CARBOXYPEPTIDASE A', 
'5EAT' => '5-EPI-ARISTOLOCHENE SYNTHASE', 
'5ENL' => 'ENOLASE', 
'5FIT' => 'FRAGILE HISTIDINE TRIAD PROTEIN', 
'5RSA' => 'RIBONUCLEASE A', 
'7ODC' => 'PROTEIN (ORNITHINE DECARBOXYLASE)', 
'8PCH' => 'CATHEPSIN H', 
);

return (%tab); 
}

sub cgi_GetTableUlta{ 
    my %tab = cgi_GetTableWithPDBid();
    my %ulta ; 
    foreach my $k (keys %tab){
	    my $v = $tab{$k};
	    $ulta{$v} = $k ; 
    }
    return (%ulta); 
}
sub cgi_GetTableWithPDBid{ 
    my %tab = cgi_GetTable();
    my %ulta ; 
    foreach my $k (keys %tab){
	    my $v = $tab{$k};
	    $ulta{$k} = "$v ($k)" ; 
    }
    return (%ulta); 
}



sub cgi_SaveFile{

        my ($q) = @_;
        my ($bytesread, $buffer);
        my $num_bytes = 1024;
        my $totalbytes;
        my $filename = $q->upload('filename');
        my $untainted_filename;

        if (!$filename) {
            #print $q->p('You must enter a filename before you can upload it');
    	    return;
        }

        # Untaint $filename

        if ($filename =~ /^([-\@:\/\\\w.]+)$/) {
            $untainted_filename = $1;
        } else {
            die <<"EOT";
    Unsupported characters in the filename "$filename". 
    Your filename may only contain alphabetic characters and numbers, 
    and the characters '_', '-', '\@', '/', '\\' and '.'
EOT
        }

        if ($untainted_filename =~ m/\.\./) {
            die <<"EOT";
    Your upload filename may not contain the sequence '..' 
    Rename your file so that it does not include the sequence '..', and try again.
EOT
        }

        my $file = "/tmp/$untainted_filename";

        print "Uploading $filename to $file<BR>" if($verbose);

        # If running this on a non-Unix/non-Linux/non-MacOS platform, be sure to 
        # set binmode on the OUTFILE filehandle, refer to 
        #    perldoc -f open 
        # and
        #    perldoc -f binmode

        open (OUTFILE, ">", "$file") or die "Couldn't open $file for writing: $!";

        while ($bytesread = read($filename, $buffer, $num_bytes)) {
            $totalbytes += $bytesread;
            print OUTFILE $buffer;
        }
        die "Read failure" unless defined($bytesread);
        unless (defined($totalbytes)) {
            print "<p>Error: Could not read file ${untainted_filename}, ";
            print "or the file was zero length.";
        } else {
            print "<p>Done. File $filename uploaded." if($verbose);
        }
        close OUTFILE or die "Couldn't close $file: $!";
		return $file; 

}


sub cgi_FormSearch {
        my ($q,$name,$file,$str) = @_;
        print $q->start_form(
            -name => $name, 
            -method => 'POST',
            -action => $file, 
        );

        print $q->start_table;
        print $q->Tr(
          $q->td($str),
          $q->td(
            $q->textfield(-name => $name, -size => 50)
          )
        );
        print $q->Tr(
          $q->td($q->submit(-value => 'Submit')),
          $q->td('&nbsp;')
        );
        print $q->end_table;

        print $q->end_form;

}



sub cgi_End{
        my ($q) = @_;
        print $q->div("My Web Form");
        print $q->end_html;
}

sub cgi_Start{
        my ($q,$title) = @_;
        print $q->start_html(
            -title => $title,
            -bgcolor => 'white',
            -style => {
	        -code => '
                    /* Stylesheet code */
                    body {
                        font-family: verdana, sans-serif;
                    }
                    h2 {
                        color: darkblue;
                        border-bottom: 1pt solid;
                        width: 100%;
                    }
                    div {
                        text-align: right;
                        color: steelblue;
                        border-top: darkblue 1pt solid;
                        margin-top: 4pt;
                    }
                    th {
                        text-align: right;
                        padding: 2pt;
                        vertical-align: top;
                    }
                    td {
                        padding: 2pt;
                        vertical-align: top;
                    }
                    /* End Stylesheet code */
                ',
	    },
        );
        print $q->h2($title);
}


sub cgi_GetEnv{
   my $SRC = $ENV{SRC} or die ;
   my $ANNDIR = $ENV{ANNDIR} or die ;
   my $PDBDIR = $ENV{PDBDIR} or die ;
   my $APBSDIR = $ENV{APBSDIR} or die ;
   return ($SRC,$ANNDIR,$PDBDIR,$APBSDIR);
}
