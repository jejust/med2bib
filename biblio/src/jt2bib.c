/* Copyright (C) 1997-2000 by Laurent Itti - All rights reserved */
/* jt2bib.c: converts ISI JTracker records to bibtex format */

#include <stdio.h>
#include <ctype.h>
#include <string.h>


typedef struct {
  char author[5000];
  char title[5000];
  char journal[500];
  char volume[20];
  char issue[20];
  char pages[30];
  char month[15];
  char year[10];
  char abstract[30000];
  char keywords[40000];
  char address[5000];
  char comment[10000];
} BibEntry;

#define K_AU ('A'*256+'U')
#define K_TI ('T'*256+'1')
#define K_VI ('V'*256+'L')
#define K_IP ('I'*256+'S')
#define K_SP ('S'*256+'P')
#define K_EP ('E'*256+'P')
#define K_TA ('J'*256+'F')
#define K_AB ('N'*256+'2')
#define K_DP ('Y'*256+'1')
#define K_U1 ('U'*256+'1')

#define LINELEN 78
static char line[1024], lin[1024];

/* ###################################################################### */
void clean_entry(BibEntry *e)
{
  e->author[0] = '\0';
  e->title[0] = '\0';
  e->journal[0] = '\0';
  e->volume[0] = '\0';
  e->issue[0] = '\0';
  e->pages[0] = '\0';
  e->month[0] = '\0';
  e->year[0] = '\0';
  e->abstract[0] = '\0';
  e->keywords[0] = '\0';
  e->address[0] = '\0';
  e->comment[0] = '\0';
}

/* ###################################################################### */
void print_entry(BibEntry *e, FILE *out)
{
  int i, j, nbauth;
  char key[100];

  if (e->author[0] == '\0')
    { fprintf(stderr, "Bogus empty entry! ... skipping ...\n"); return; }

  /* only print out entries of type "Article" */
  if (strcmp(e->comment, "Article")) return;
  e->comment[0] = '\0';   /* remove fake comment */

  /* generate key: */
  i = 0; nbauth = 0; key[0] = '\0';
  while(i < strlen(e->author)-4)
    {
      if (!strncmp(&(e->author[i]), " and ", 5)) nbauth ++;
      i ++;
    }
  switch(nbauth)
    {
    case 0:
      i = 0; while(e->author[i] != ' ' || e->author[i+2] == '.') i++;
      strcpy(key, &(e->author[i+1])); strcat(key, &(e->year[2]));
      break;
    case 1:
      i = 0; while(strncmp(&(e->author[i]), " and ", 5)) i++;
      j = i + 5; i = 0; while(e->author[i]!=' ' || e->author[i+2]=='.') i++;
      strncpy(key, &(e->author[i+1]), j-i-6); key[j-i-6] = 0;
      strcat(key, "_"); while(e->author[j]!=' ' || e->author[j+2]=='.') j ++;
      strcat(key, &(e->author[j+1])); strcat(key, &(e->year[2]));
      break;
    default:
      i = 0; while(strncmp(&(e->author[i]), " and ", 5)) i++;
      j = i + 5; i = 0; while(e->author[i]!=' ' || e->author[i+2]=='.') i++;
      strncpy(key, &(e->author[i+1]), j-i-6); key[j-i-6] = 0;
      strcat(key, "_etal"); strcat(key, &(e->year[2]));
    }
  j = 0; i = 0;
  while(key[i] != '\0') { if (key[i] != ' ') key[j++] = key[i]; i++; }
  key[j] = '\0';

  /* clean-up potential trailing dot from title: */
  if (e->title[strlen(e->title)-1] == '.') e->title[strlen(e->title)-1] = '\0';

  fprintf(out, "@Article{%s,\n", key);
  fprintf(out, "author  =\"%s\",\n", e->author);
  fprintf(out, "title   ={%s},\n", e->title);
  fprintf(out, "journal ={%s},\n", e->journal);
  fprintf(out, "volume  ={%s},\n", e->volume);
  fprintf(out, "number  ={%s},\n", e->issue);  
  fprintf(out, "pages   ={%s},\n", e->pages);
  fprintf(out, "month   ={%s},\n", e->month);
  fprintf(out, "year    ={%s},\n", e->year);
  fprintf(out, "abstract={%s},\n", e->abstract);
  fprintf(out, "keyword ={%s},\n", e->keywords);
  fprintf(out, "address ={%s},\n", e->address);  
  fprintf(out, "note    ={%s}\n", e->comment);  
  fprintf(out, "}\n\n");

  fprintf(stderr, "jt2bib: %s, %s %s;%s(%s):%s\n",
	  key, e->journal, e->year, e->volume, e->issue, e->pages);
}

/* ###################################################################### */
void concat(char *dest, char *src)
{
  int i, len;
  
  while(src[strlen(src)-1] == '\n' || src[strlen(src)-1] == ' ')
    src[strlen(src)-1] = '\0';
  if (dest[0] != '\0')
    if (dest[strlen(dest)-1] != ' ' && src[0] != ' ') strcat(dest, " ");

  /* find current line len: */
  i = strlen(dest) - 1; while(i > 0 && dest[i] != '\n') i --;
  if (i > 0) len = strlen(dest) - i + 2; else len = 10 + strlen(dest);
  if (len >= LINELEN) /* screwed up last time! */
    { strcat(dest, "\n"); len = 0; }

  /* can we add src into this line ? */
  if (len + strlen(src) >= LINELEN)
    {
      i = LINELEN - len;  /* point where we want to cut */
      while (i > 0 && src[i] != ' ') i --;
      if (i == 0) strcat(dest, "\n"); else src[i] = '\n';
      while(strlen(&(src[i+1])) > LINELEN)
	{
	  i += LINELEN;  /* point where we want to cut */
	  while (i > 0 && src[i] != ' ') i --;
	  src[i] = '\n';
	}
    }
  strcat(dest, src);
}

void cleanup(char *src, char *dest)
{
  int i, j; char c;
  i = 0; j = 0;
  while((c = src[i++]) != '\0')
    switch(c)
      {
      case '\n':
	break;
      case '>':
      case '<':
      case '\"':  /* " emacs bug! */
      case '#':
      case '$':
      case '^':
      case '\\':
      case '_':
      case '{':
      case '}':
      case '&':
      case '%':
	dest[j++] = '\\'; dest[j++] = c; break;
      case '~':
	dest[j++] = '$'; dest[j++] = '\\'; dest[j++] = 's';
	dest[j++] = 'i'; dest[j++] = 'm'; dest[j++] = '$'; break;
      default:
	dest[j++] = c; break;
      }
  dest[j] = '\0';
}

void clean_caps(char *str)
{
  int i, j, new_word, wlen;
  i = 0; new_word = 1; wlen = 1000; /* start of a new word */
  while (str[i] != '\0')
    {
      if (new_word == 0)
	{
	  if (wlen < 1000)
	    str[i] = (char)( tolower((int)(str[i])) );
	}
      else
	{
	  new_word = 0; wlen = 0; j = i;
	  while(str[j] != ' ' && str[j] != '-' && str[j] != '\0')
	    {
	      if (!isalpha(str[j]) && str[j] != ',')
		{ wlen = 1000; break; } /* ->uppercase */
	      j++; wlen++;
	    }
	  if (wlen <= 3 && (wlen > 1 || (str[i] == 'A' && str[i+1] == ' ')))
	    str[i] = (char)( tolower((int)(str[i])) );
	}
      if (str[i] == ' ' || str[i] == '-') new_word = 1;
      i ++;
    }
  str[0] = (char)(toupper((int)(str[0])));
}

/* ###################################################################### */
int main(int argc, char **argv)
{
  FILE *in, *out;
  BibEntry e;
  char ontheway = 0, tmp[20], prevblank = 0, first_ever = 1, c;
  int key, i, j, i0, len;
  
  clean_entry(&e);

  if (argc > 1)
    {
      in = fopen(argv[1], "r");
      if (in == 0)
	{ fprintf(stderr, "%s: Cannot read '%s'\n", argv[0], argv[1]);
	exit(1); }
    }
  else in = stdin;
  
  if (argc > 2)
    {
      out = fopen(argv[2], "a");
      if (out == 0)
	{ fprintf(stderr, "%s: Cannot write '%s'\n", argv[0], argv[2]);
	exit(1); }
    }
  else out = stdout;

  if (argc > 3)
    { fprintf(stderr, "USAGE: %s [infile] [outfile]\n", argv[0]);
    exit(1); }

  while(fgets(lin, 1024, in))
    {
      cleanup(lin, line);
      if (isdigit(line[0]) ||
	  ((prevblank != 0 || first_ever != 0) 
	   && line[0] == 'T' && line[1] == 'Y')) /* new entry */
	{
	  if (ontheway) print_entry(&e, out);
	  clean_entry(&e); ontheway = 1;
	}
      else if (ontheway && line[0] != '\n' && line[0] != '\0')
	{
	  if (line[0] == '=')
	    { print_entry(&e, out); fclose(in); fclose(out); exit(0); }
	  if (line[0] != ' ') key = ((int)(line[0]))*256+((int)(line[1]));
	  switch(key)
	    {
	    case K_AU:   /* authors->need to put initials first */
	      if (strlen(e.author) > 0) concat(e.author, "and");
	      i = strlen(line) - 1; 
	      if (i > 5) {   /* sometimes that field is empty!! */
		while(line[i] != ',') i--;
		j = 0; i0 = i; i++; while(line[i] != '\0' && line[i] != '\n')
		  { tmp[j++] = line[i]; if (line[i++] == '.') tmp[j++] = ' '; }
		tmp[j] = '\0'; concat(e.author, tmp); line[i0] = '\0';
		concat(e.author, &(line[6]));
	      }
	      break;
	    case K_TI:
	      concat(e.title, &(line[6]));
	      break;
	    case K_U1:
	      concat(e.comment, &(line[6]));
	      break;
	    case K_VI:
	      concat(e.volume, &(line[6]));
	      break;
	    case K_IP:
	      concat(e.issue, &(line[6]));
	      break;
	    case K_SP:
	      strcpy(e.pages, &(line[6])); strcat(e.pages, "-");
	      break;
	    case K_EP:
	      strcat(e.pages, &(line[6]));
	      break;
	    case K_TA:
	      clean_caps(&(line[6]));  /* convert journal to clean caps */
	      concat(e.journal, &(line[6]));
	      break;
	    case K_AB:
	      concat(e.abstract, &(line[6]));
	      break;
	    case K_DP:
	      i=6; while(line[i] != '/') i++; line[i] = '\0';
	      strcpy(e.year, &(line[6]));
	      break;
	    default: break;
	    }
	}
      if (line[0] == '\0' || line[0] == ' ') prevblank = 1; else prevblank = 0;
      first_ever = 0;
    }
  print_entry(&e, out);
  
  fclose(in);
  fclose(out);

  exit(0);
}

