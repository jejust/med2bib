/* Copyright (C) 1997 by Laurent Itti - All rights reserved */
/* med2bib.c: converts Medline "DISPLAY MEDLINE" records to bibtex
   format */

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
#define K_TI ('T'*256+'I')
#define K_VI ('V'*256+'I')
#define K_IP ('I'*256+'P')
#define K_PG ('P'*256+'G')
#define K_TA ('T'*256+'A')
#define K_MH ('M'*256+'H')
#define K_AB ('A'*256+'B')
#define K_DP ('D'*256+'P')
#define K_AD ('A'*256+'D')
#define K_CM ('C'*256+'M')
#define K_LA ('L'*256+'A')
#define K_SO ('S'*256+'O')

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

/* correct_pages: reformat pages to long format (i.e., 1234-1256 instead of
   Medline's native 1234-56). Contributed by Olav Kongas
   <ok@mito.physiol.med.vu.nl>  <kongas@ioc.ee> */
void correct_pages(BibEntry *e)
{
  int i;
  char firstpg[14], lastpg[14], *minus;
  for (i = 0; i < 14 ; i++) firstpg[i] = lastpg[i] = '\0';
  minus = strchr(e->pages, '-');
  strncpy(firstpg, e->pages, (int)(minus - e->pages));
  strcpy(lastpg, minus + 1);
  for (i = 0; i < ((int)strlen(firstpg) - (int)strlen(lastpg)); i++)
    minus[i + 1] = firstpg[i];
  strcpy(minus + i+1, lastpg) ;
}

/* ###################################################################### */
void print_entry(BibEntry *e, FILE *out)
{
  int i, j, nbauth;
  char key[100];

  if (e->author[0] == '\0')
    { fprintf(stderr, "Bogus empty entry! ... skipping ...\n"); return; }

  /* clean up page numbers: */
  correct_pages(e);

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

  fprintf(stderr, "med2bib: %s, %s %s;%s(%s):%s\n",
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

/* ###################################################################### */
int main(int argc, char **argv)
{
  FILE *in, *out;
  BibEntry e;
  char ontheway = 0, tmp[20], prevblank = 0, first_ever = 1, c,
    detailed_info = 0;
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
	   && line[0] == 'U' && line[1] == 'I')) /* new entry */
	{
	  if (ontheway) print_entry(&e, out);
	  clean_entry(&e); detailed_info = 0; ontheway = 1;
	}
      else if (ontheway && line[0] != '\n' && line[0] != '\0')
	{
	  if (line[0] != ' ') key = ((int)(line[0]))*256+((int)(line[1]));
	  switch(key)
	    {
	    case K_AU:   /* authors->need to put initials first */
	      if (strlen(e.author) > 0) concat(e.author, "and");
	      i = strlen(line) - 1; while(line[i] != ' ') i--;
	      j = 0; i0 = i; i++; while(line[i] != '\0' && line[i] != '\n')
		{ tmp[j++] = line[i++]; tmp[j++] = '.'; tmp[j++] = ' '; }
	      tmp[j] = '\0'; concat(e.author, tmp); line[i0] = '\0';
	      concat(e.author, &(line[6]));
	      break;
	    case K_TI:
	      concat(e.title, &(line[6]));
	      break;
	    case K_VI:
	      concat(e.volume, &(line[6])); detailed_info = 1;
	      break;
	    case K_IP:
	      concat(e.issue, &(line[6])); detailed_info = 1;
	      break;
	    case K_PG:
	      concat(e.pages, &(line[6])); detailed_info = 1;
	      break;
	    case K_TA:
	      concat(e.journal, &(line[6])); detailed_info = 1;
	      break;
	    case K_MH:
	      if (strlen(e.keywords) > 0) concat(e.keywords, "|");
	      concat(e.keywords, &(line[6]));
	      break;
	    case K_AB:
	      concat(e.abstract, &(line[6]));
	      break;
	    case K_DP:
	      strncpy(e.year, &(line[6]), 4); detailed_info = 1;
	      if (strlen(line) > 10)
		{ strncpy(e.month, &(line[11]), 3); e.month[3] = '\0'; }
	      break;
	    case K_AD:
	      concat(e.address, &(line[6]));
	      break;
	    case K_CM:
	      concat(e.comment, &(line[6]));
	      break;
	    case K_LA:
	      if (line[6] != 'E' || line[7] != 'n' || line[8] != 'g')
		{
		  /* not english -> add language to the comment */
		  concat(e.comment, "("); strcat(e.comment, &(line[6]));
		  strcat(e.comment, ")");
		}
	      break;
	    case K_SO:  /* abbreviated journal name, vol, issue, etc. */
	      if (detailed_info == 0)  /* use only if don't have details */
		{
		  len = strlen(line);
		  /* look for 4 digits: year */
		  for (i = 6; i < len-4; i ++)
		    if (isdigit(line[i]) && isdigit(line[i+1]) &&
			isdigit(line[i+2]) && isdigit(line[i+3])) break;
		  if (i == len - 4)  /* multiline journal name */
		    { concat(e.journal, &(line[6])); break; }
		  line[i-1] = '\0'; line[i+4] = '\0';
		  concat(e.journal, &(line[6]));
		  strncpy(e.year, &(line[i]), 4);
		  i += 5; j = i;
		  while(line[j] != ';' && j < len) j ++;
		  line[j] = '\0'; strcpy(e.month, &(line[i])); j ++; i = j;
		  while(line[j] != '(' && line[j] != ':' && j < len) j ++;
		  c = line[j]; line[j] = '\0'; j ++;
		  strcpy(e.volume, &(line[i]));
		  if (c == '(')  /* have an issue number */
		    { i = j; while(line[i] != ')') i ++; line[i] = '\0';
		    strcpy(e.issue, &(line[j])); j = i+2; }
		  strcpy(e.pages, &(line[j]));
		}
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

