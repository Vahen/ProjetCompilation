%{
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#define MAX_SIZE 256

/* A modifier */
typedef enum{
	false=0,
	true
}Bool;

typedef enum {
	voide=0,
	caracter,
	integer
}Type;

typedef struct {
	Type type;/*0: voide 
				1 : caracter
				2 : integer 
			  	*/
	char name[MAX_SIZE];
	/*int size; inutile */ 
	int value;
	
	/* Rajouter une variable pour indiquer qu'un symbol est "mort" et donc reutilisable -> fait avec nbElemFonc */

}Symbol;


typedef struct {

	char name[MAX_SIZE];
	Type typeRetour; /* A voir pour l'utilisation */
	int label;

}Func;

 int yyerror(char*);
 int yylex();
 FILE* yyin; 
 
 int jump_label=0, jump_label_main;
 void inst(const char *);
 void instarg(const char *,int);
 void comment(const char *);
 
 
 int find(char*); /* Verifie si le symbole donné est dans la table */
 
 void insert_value(int,Type);
 void insert_type(Type);
 
 
 void insert_symbol(char*); /* insert le symbole "symbol" de type "type" dans la table*/
 void update_symbol(char*,int);/* Met a jour le symbol dans le table*/
 
 void delete_symbol_fonc();
 
  /* Modifier les 2 fonctions
	-> utiliser table des symbole
 */
 /*
 void stockage(void);
 void restoration(void); */
 void ifand();
 void ifor();
 
 int find_fonc(char*);
 void insert_fonc_tab(char*,int,Type);
 
 void printTabFunc();
 
 
 int nbElemTable=0; /* Nombre de variable dans la table */
 int nbElemFonc=0; /* Nombre de variable dans la fonctions */
 
 int nbFunc=0;
 
 Symbol table[2048]; /*MAX_SIZE]; Table des symbol */
 Func tableFunc[1024];
 
%}


%left NOTELSE
%left ELSE



%left '|'
%left '&'
%left '!'
%left '<'
%left '>'

%left '='
%left '+'
%left '-'
%left '%'
%left '*'
%left '/'
%left '('
%left ')'

%token IF ELSE PRINT 

%token WHILE 
%token MAIN
%token VOID
%token RETURN

%token CONST
%token INT CHAR
%token TRUE FALSE


%union {
	int entier;
	char string[256];
	char caract;
}


%token <entier> NUM READ
%token <string> IDENT 
%token <caract> CARACTERE READCH

%type <entier> LABEL JUMPIF JUMPWHILE

/*
%type <entier> Ifbool IfboolONE

%type <entier> JUMPELSE JUMPIFEQUAL JUMPIFNOT JUMPIFNOTEQUAL JUMPIFGEQ JUMPIFGREATER JUMPIFLEQ JUMPIFLESS
*/
%type <entier> JUMPELSE 
%type <entier> Exp NombreSigne 
%type <string> LValue




%%

Progamme : 
	/* Jump au label du main  */
	DeclConst {jump_label_main = jump_label; instarg("JUMP",jump_label++);} DeclVarPuisFonct DeclMain
    ;

/* Declaration de la liste des constante */	
DeclConst: 
	/* vide */
	| CONST ListConst ';' DeclConst /* Ajout dans table des symbol */	   
	;
  
ListConst : 
	IDENT '=' Litteral ',' {insert_symbol((char*)$1);} ListConst 
	| IDENT '=' Litteral {insert_symbol((char*)$1);}
	;
Litteral :
	NombreSigne {printf("#---Nombre signe $1 = %d\n",$1); insert_value($1,2);}
	| CARACTERE { insert_value($1,1);}
	;

NombreSigne:
	NUM {$$=$1;}
	| '+' NUM {$$=$2;}
	| '-' NUM {$$=$2;}
	;

DeclVarPuisFonct :
	/* vide */
	| INT ListVar ';' DeclVarPuisFonct
	| CHAR ListVar ';' DeclVarPuisFonct
	| DeclFonct
	;
	
/* endroit ou Rajouter dans table des symbol */
ListVar : 
	Ident ',' ListVar /*{insert_symbol((char*)$1);}*/
	| Ident /*{insert_symbol((char*)$1);}*/
	;
Ident : 
	IDENT Tab
	;
Tab : 
	/* vide */
	| '[' NUM ']' Tab 	
	;
DeclMain :
	EnTeteMain { instarg("LABEL",jump_label_main);}Corps 
	;
EnTeteMain: 
	MAIN '(' ')'
	;
DeclFonct : 
	DeclUneFonct DeclFonct
	| DeclUneFonct
	;
DeclUneFonct:
	EnTeteFonct { nbElemFonc = 0;instarg("LABEL",jump_label++);}
				Corps {delete_symbol_fonc();}
	;
EnTeteFonct : 
	INT IDENT '(' Parametres ')' {insert_fonc_tab($2,jump_label,2);
									/* Bidouille */
									/*tableFunc[nbFunc-1].typeRetour=2;
									tableFunc[nbFunc-1].label=jump_label;
									*/
									/*tableFunc[0].typeRetour = 2;*/}								
	| CHAR IDENT '(' Parametres ')' {insert_fonc_tab($2,jump_label,1);}
	| VOID IDENT '(' Parametres ')' {insert_fonc_tab($2,jump_label,0);}
	;
Parametres : 
	VOID
	| ListTypVar
	;
ListTypVar :
	INT IDENT ',' ListTypVar
	| CHAR IDENT ',' ListTypVar  
	| INT IDENT /*{ insert_symbol($2,integer); }*/
	| CHAR IDENT /*{ insert_symbol($2,caracter); }*/	
	;
Corps : 
	'{' DeclConst DeclVar SuiteInstr '}'
	;

/* Declaration des variables
	forme : 
	int x,z;
	int y;
	Pas affectation a la declaration
 */	
DeclVar : 
	/*vide*/
	| DeclVar INT ListVar ';' /* Ajout dans table des symbole */ 
	| DeclVar CHAR ListVar ';' /* Ajout dans table des symbole */
	;

SuiteInstr :
	/*vide*/
	| Instr SuiteInstr       
    ;
	
	
/* Faire le truc sur les variables */	
Instr :
	LValue '=' Exp ';' { printf("#------- %s = %d\n",$1,$3);update_symbol ($1,$3); }
	/*| IF '(' Ifbool JUMPIF {instarg("LABEL",$3);} ')' InstrIF
		*/
			
	/*
	| IF '(' IFBOOL ')' JUMPIF INSTRUCTION %prec NOTELSE {instarg ("LABEL", $5) ; }

	| IF '(' IFBOOL ')' JUMPIF INSTRUCTION ELSE JUMPELSE{ instarg("LABEL", $5) ; } INSTRUCTION{ instarg("LABEL", $8) ;}	
	  
	| WHILE  { instarg("LABEL",$$=jump_label++);} '(' IFBOOL ')' 
	{inst("POP");jump_label++;instarg("JUMPF",$$=jump_label++);instarg("LABEL",$2+1);}      	
	INSTRUCTION	{instarg("JUMP",$2); instarg("LABEL",$6);} 

	*/		
	
		/* A corriger peut etre */ 
	/*| IF '(' Exp ')' JUMPIF Instr %prec NOTELSE {instarg ("LABEL", $5) ; }

	| IF '(' Exp ')' JUMPIF Instr ELSE JUMPELSE{ instarg("LABEL", $5) ; } Instr { instarg("LABEL", $8) ;}	
		*/
		
	| IF '(' Exp ')' JUMPIF Instr %prec NOTELSE {instarg ("LABEL", $5) ; }

	| IF '(' Exp ')' JUMPIF Instr ELSE JUMPELSE{ instarg("LABEL", $5) ; } Instr { instarg("LABEL", $8) ;}		
		
	| WHILE  LABEL '(' Exp ')' JUMPWHILE {instarg("LABEL",$2+1);} Instr {instarg("JUMP",$2); instarg("LABEL",$6);}	
	/*| WHILE LABEL '(' Exp ')' JUMPIF	Instr {instarg("JUMP",$2); instarg("LABEL",$6);}
	*/
	| RETURN Exp ';' { /* $$=Exp Jump */
		instarg("SET",$2);inst("PUSH");inst("RETURN");
	}
	| RETURN ';' { /* Jump */
		inst("RETURN");
	}
	/* Appel d'une fonction' */
	| IDENT '(' Arguments ')' ';' { int i=find_fonc($1);
									if(i>=0){ 
										instarg("CALL",i);	
									} 
									else { printf("%s doesn't exist\n",$1); exit(EXIT_FAILURE);} ;
	
	}
		/* Lis un entier tape au clavier -> creation d'un symbol dans la table */
	| READ '(' IDENT ')' ';'  { inst("READ");inst("PUSH");
	
	} 
		/* Lis un caracter tape au clavier -> creation d'un symbol dans la table */
	| READCH '(' IDENT ')' ';' { inst("READCH");inst("PUSH");

	}
	| PRINT '(' Exp {inst("POP");inst("WRITE");comment("---affichage");}')' ';' 
	/* recup symbole dans la table , push symbol -> pop -> write */
	| ';'
	| '{' SuiteInstr '}'
	;	

/* 
IF '(' Exp ')' JUMPIF Instr %prec NOELSE {instarg ("LABEL", $5) ; }

IF '(' Exp ')' JUMPIF Instr ELSE JUMPELSE{ instarg("LABEL", $5) ; } Instr { instarg("LABEL", $8) ;}

*/	
	
Arguments: 
	/* vide */ 
	| ListExp
	;

LValue :
	IDENT TabExp { }	
	;
TabExp:
	/* vide */
	| TabExp '[' Exp ']' 

	;

ListExp : 
	ListExp ',' Exp 
	| Exp  
	;	

 
Exp : 
	/* Exp ADDSUB Exp */
	Exp '+' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("ADD");
		inst("PUSH");
	}
	| Exp '-' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("SUB");
		inst("PUSH");
	}
	
	/* Exp DIVSTAR Exp */
	| Exp '*' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MUL");
		inst("PUSH");
	}	
	| Exp '/' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("DIV");
		inst("PUSH");
	}
	| Exp '%' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("MOD");
		inst("PUSH");
	}
    | Exp '<' Exp {
		inst("POP");
		inst("SWAP"); 
		inst("POP");
		inst("LESS");
		inst("PUSH");
	}
	/* Exp Comp Exp */
    | Exp '>' Exp {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("GREATER");
		inst("PUSH");
	}
    | Exp '<''=' Exp  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LEQ");
		inst("PUSH");
	}     
    | Exp '>''=' Exp {
    	inst("POP"); 
        inst("SWAP"); 
		inst("POP");
		inst("GEQ");
		
		inst("PUSH");
	}
    | Exp '=''=' Exp {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("EQUAL");
		inst("PUSH");
	}
    | Exp '!''=' Exp {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("NOTEQ");
		inst("PUSH");
	}
    /* ADDSUB Exp */
	| '(' '-' Exp ')' {
		inst("POP");
		inst("NEG");
		inst("PUSH"); 
	}
	
	/*| Ifbool*/
	/*Exp BOPE Exp */
	| Exp '|' '|' Exp {ifor();$$=$4;}
	| Exp '&' '&' Exp {ifand();$$=$4;}
	/* IfboolONE */
	
	
    | '!' Exp { inst("POP");
		inst("NEG");
		inst("SWAP");
		instarg("SET",1);
		inst("ADD");
		inst("PUSH");}
	| TRUE {instarg("SET",1); inst("PUSH");}
	| FALSE {instarg("SET",0); inst("PUSH");}

	
	/* NEGATION Exp */	
	
	/* */
	| '(' Exp ')' { $$=$2; }
	| LValue {int i=find($1);fprintf(stdout,"#---$1 = %s i = %d table[%d].value = %d\n",$1,i,i,table[i].value);
				 if(i>=0){
				 	instarg("SET",table[i].value);
				 	inst("PUSH");
				 } 
				 else { 
				 	printf("#---%s doesn't exist\n",$1); 
				 	exit(EXIT_FAILURE);
				 }
	}
	| NUM { 
		instarg("SET",$1);
        inst("PUSH"); 
    }
	| CARACTERE { /* A voir */
		instarg("SET",$1);
        inst("PUSH"); 
	}
	| IDENT '(' Arguments ')' { } /* Jump -> label fonctions */
  ;

/*
InstrIF :
	 Instr %prec NOTELSE {instarg("LABEL",jump_label++);}
     | Instr ELSE JUMPELSE {instarg("LABEL",$3-1);} Instr {instarg("LABEL",$3);}
	 ;
	*/ 
	
/* Exp BOPE Exp */	
/*
Ifbool:
	 IfboolONE  '|' '|' Ifbool {ifor();$$=$4;}
	 | IfboolONE '&' '&' Ifbool {ifand();$$=$4;}	 
	 | IfboolONE {$$=$1;}
	;*/
/* Exp comp Exp */
/*
IfboolONE: 
    Exp '<' Exp JUMPIFLESS { $$=$4;}
    |  Exp '>' Exp JUMPIFGREATER { $$=$4;}
    |  Exp '<''=' Exp JUMPIFLEQ {$$=$5;}    
    |  Exp '>''=' Exp JUMPIFGEQ {$$=$5;}
    |  Exp '=''=' Exp JUMPIFEQUAL {$$=$5;}
    |  Exp '!''=' Exp JUMPIFNOTEQUAL {$$=$5;}
    | '!' Exp JUMPIFNOT {$$=$3;}
	| TRUE {instarg("SET",1); inst("PUSH");}
	| FALSE {instarg("SET",0); inst("PUSH");}
	;
*/
/*
JUMPIFNOT:{
		inst("POP");
		inst("NEG");
		inst("SWAP");
		instarg("SET",1);
		inst("ADD");
		inst("PUSH");
		}
	;

JUMPIFEQUAL:{
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("EQUAL");
		$$=jump_label;
		inst("PUSH");
	}
	;
JUMPIFNOTEQUAL:{
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("NOTEQ");
		$$=jump_label;
		inst("PUSH");
	}
	;   	      
JUMPIFLESS :  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LESS");
		$$=jump_label;
		inst("PUSH");
	}
	;
JUMPIFLEQ :  {
		inst("POP"); 
		inst("SWAP"); 
		inst("POP");
		inst("LEQ");
		$$=jump_label;
		inst("PUSH");
	}
	;	 
JUMPIFGREATER :  {
		inst("POP"); 
    	inst("SWAP"); 
		inst("POP");
		inst("GREATER");
		$$=jump_label;
		inst("PUSH");
	}	 
	;
JUMPIFGEQ :  {
		inst("POP"); 
        inst("SWAP"); 
		inst("POP");
		inst("GEQ");
		$$=jump_label;
		inst("PUSH");
	 }	 
	 ;	
	 */  
JUMPELSE : {
	instarg("JUMP", $$=jump_label++);

	}	 
	;

LABEL : {
	instarg("LABEL",$$=jump_label++);
	}
	;
	
JUMPIF :{
	inst("POP");
	instarg("JUMPF", $$=jump_label+1);
	instarg("LABEL",jump_label++);
	jump_label++;
};

JUMPWHILE : {
	inst("POP");
	jump_label++;
	instarg("JUMPF",$$=jump_label++);


}
;


%%

/* Recupere la val en sommet de pile et la place à l'adresse 0 */ 
void stockage(){
	instarg("SET",0);
	inst("SWAP"); 
	inst("POP");
	inst("SAVE");
}

/* Recupere la val à l'adresse 0 et la place en sommet de la pile */
void restoration(){
	instarg("SET",0);
	inst("LOAD");
	inst("PUSH");
}

void ifor(){
	inst("POP");
	inst("NEG");
	inst("SWAP");
	instarg("SET",1);
	inst("ADD");
	instarg("JUMPF",jump_label);

}

void ifand(){
	inst("POP");
	inst("SWAP");
	inst("POP");
	inst("ADD");
	inst("SWAP");
	instarg("SET",2);
	inst("LEQ");
	inst("PUSH");

}

void init_string(char *string,int size){
	int i;
	for(i=0;i<size;i++){
		string[i]='\0';
	}
}

void printTabFunc(){
	int i;
	for(i=nbFunc-1;i>=0;i--){
		fprintf(stdout,"#------i = %d name : %s Type : %d Label : %d \n",i,tableFunc[i].name,tableFunc[i].typeRetour,tableFunc[i].label);
	}
}

int find(char *symbol){
	int i;
	
	for(i=nbElemTable;i>=0;i--){
		/*fprintf(stdout,"#------symbol = %s,table[%d].name = %s\n",symbol,i,table[i].name);*/
		if(strcmp(table[i].name,symbol)==0)
			return i;
	}
	return -1;
}

void insert_value(int value,Type type){
	table[nbElemTable].value=value;
	insert_type(type);
}
void insert_type(Type type){
	table[nbElemTable].type = type;
}

void insert_symbol(char* symbol){
	if(find(symbol)<0){
		/*table[nbElemTable].name=(char*)calloc(sizeof(char),strlen(symbol)+1);*/
		strncpy(table[nbElemTable].name,symbol,strlen(symbol)+1);
		nbElemTable++;
		nbElemFonc++;
		/*if(NULL ==(table = (Symbol*)realloc(table,nbElemTable+1))){
			perror("realloc\n");
			exit(EXIT_FAILURE);
		}*/
	}
	else{
		fprintf(stdout,"Redeclaration of variable %s\n",symbol);	
	}	
}

void update_symbol(char* symbol,int value){
	int i=-1;
	if(0<=(i=find(symbol))){
		table[i].value = value;
	}
}


void delete_symbol_fonc(){
	int i=-1;
	for(i=nbElemTable-1;i>nbElemTable-nbElemFonc-1;i--){
		/*if(NULL ==(table = (Symbol*)realloc(table,i))){
			perror("realloc\n");
			exit(EXIT_FAILURE);
		}*/
	}
	nbElemTable-=nbElemFonc;
	nbElemFonc=0;
}

/* Renvoie le label de la fonction s'il trouve , -1 sinon */
int find_fonc(char* name){
	int i;
	/*printTabFunc();*/
	for(i=nbFunc-1;i>=0;i--){
		if(strcmp(tableFunc[i].name,name)==0)
			return tableFunc[i].label;
	}
	return -1;
}

void insert_fonc_tab(char* name,int label,Type type){
	if(find_fonc(name)<0){
		init_string(tableFunc[nbFunc].name,MAX_SIZE);
		strncpy(tableFunc[nbFunc].name,name,strlen(name)+1);		
		tableFunc[nbFunc].typeRetour=type; /* N'a aucun effet */
		tableFunc[nbFunc].label=label; /* N'a aucun effet */
		nbFunc++;
		
		/*if(NULL ==(tableFunc = (Func*)realloc(tableFunc,nbFunc+1))){
			perror("realloc\n");
			exit(EXIT_FAILURE);
		}
		*/
		
	}
	else{
		fprintf(stdout,"Redeclaration of function %s\n",name);	
	}

}

/*
void init_table_symbol(){
	/* Alloc du tableau de taille 0 /
  	if(NULL ==(table = (Symbol*)malloc((nbElemTable+1)*sizeof(Symbol)))){
		perror("malloc\n");
		exit(EXIT_FAILURE);
 	}
 	
 	
}
*/
/*
void init_table_func(){
	if(NULL ==(tableFunc = (Func*)malloc((nbFunc+1)*sizeof(Func)))){
		perror("malloc\n");
		exit(EXIT_FAILURE);
 	}
}
*/
void init(){
/*
	init_table_symbol();
	init_table_func();
*/
}


int yyerror(char* s) {
  fprintf(stderr,"%s\n",s);
  return 0;
}

void endProgram() {
  printf("HALT\n");
}

void inst(const char *s){
  printf("%s\n",s);
}

void instarg(const char *s,int n){
  printf("%s\t%d\n",s,n);
}


void comment(const char *s){
  printf("#%s\n",s);
}

int main(int argc, char** argv) {
  if(argc==2){
    yyin = fopen(argv[1],"r");
  }
  else if(argc==1){
    yyin = stdin;
  }
  else{
    fprintf(stderr,"usage: %s [src]\n",argv[0]);
    return 1;
  }
  init();
  yyparse();

  endProgram();
  return 0;
}
