/* Generated by Frama-C */
#include "stdio.h"
#include "stdlib.h"
int A = 1;
int B = 2;
int C = 3;
void __e_acsl_globals_init(void)
{
  static char __e_acsl_already_run = 0;
  if (! __e_acsl_already_run) {
    __e_acsl_already_run = 1;
    __e_acsl_store_block((void *)(& B),(size_t)4);
    __e_acsl_full_init((void *)(& B));
  }
  return;
}

int main(int argc, char **argv)
{
  int __retres;
  __e_acsl_memory_init(& argc,& argv,(size_t)8);
  __e_acsl_globals_init();
  int *p = (int *)0;
  __e_acsl_store_block((void *)(& p),(size_t)8);
  __e_acsl_full_init((void *)(& p));
  int *q = (int *)0;
  int a = 1;
  int b = 2;
  __e_acsl_store_block((void *)(& b),(size_t)4);
  __e_acsl_full_init((void *)(& b));
  int c = 3;
  __e_acsl_full_init((void *)(& p));
  p = & b;
  /*@ assert \valid(p); */
  {
    int __gen_e_acsl_initialized;
    int __gen_e_acsl_and;
    __gen_e_acsl_initialized = __e_acsl_initialized((void *)(& p),
                                                    sizeof(int *));
    if (__gen_e_acsl_initialized) {
      int __gen_e_acsl_valid;
      __gen_e_acsl_valid = __e_acsl_valid((void *)p,sizeof(int),(void *)p,
                                          (void *)(& p));
      __gen_e_acsl_and = __gen_e_acsl_valid;
    }
    else __gen_e_acsl_and = 0;
    __e_acsl_assert(__gen_e_acsl_and,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(p)",24);
  }
  /*@ assert ¬\valid(p + 1); */
  {
    int __gen_e_acsl_valid_2;
    __gen_e_acsl_valid_2 = __e_acsl_valid((void *)(p + 1),sizeof(int),
                                          (void *)p,(void *)(& p));
    __e_acsl_assert(! __gen_e_acsl_valid_2,(char *)"Assertion",
                    (char *)"main",(char *)"!\\valid(p + 1)",26);
  }
  __e_acsl_full_init((void *)(& p));
  p = & B;
  /*@ assert \valid(p); */
  {
    int __gen_e_acsl_initialized_2;
    int __gen_e_acsl_and_2;
    __gen_e_acsl_initialized_2 = __e_acsl_initialized((void *)(& p),
                                                      sizeof(int *));
    if (__gen_e_acsl_initialized_2) {
      int __gen_e_acsl_valid_3;
      __gen_e_acsl_valid_3 = __e_acsl_valid((void *)p,sizeof(int),(void *)p,
                                            (void *)(& p));
      __gen_e_acsl_and_2 = __gen_e_acsl_valid_3;
    }
    else __gen_e_acsl_and_2 = 0;
    __e_acsl_assert(__gen_e_acsl_and_2,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(p)",29);
  }
  /*@ assert ¬\valid(p + 1); */
  {
    int __gen_e_acsl_valid_4;
    __gen_e_acsl_valid_4 = __e_acsl_valid((void *)(p + 1),sizeof(int),
                                          (void *)p,(void *)(& p));
    __e_acsl_assert(! __gen_e_acsl_valid_4,(char *)"Assertion",
                    (char *)"main",(char *)"!\\valid(p + 1)",31);
  }
  char *pmin = malloc(sizeof(int));
  __e_acsl_store_block((void *)(& pmin),(size_t)8);
  __e_acsl_full_init((void *)(& pmin));
  char *pmax = malloc(sizeof(int));
  __e_acsl_store_block((void *)(& pmax),(size_t)8);
  __e_acsl_full_init((void *)(& pmax));
  if ((unsigned long)pmin > (unsigned long)pmax) {
    char *t = pmin;
    __e_acsl_store_block((void *)(& t),(size_t)8);
    __e_acsl_full_init((void *)(& t));
    __e_acsl_full_init((void *)(& pmin));
    pmin = pmax;
    __e_acsl_full_init((void *)(& pmax));
    pmax = t;
    __e_acsl_delete_block((void *)(& t));
  }
  __e_acsl_initialize((void *)pmin,sizeof(char));
  *pmin = (char)'P';
  __e_acsl_initialize((void *)pmax,sizeof(char));
  *pmax = (char)'L';
  int diff = (int)((unsigned long)pmax - (unsigned long)pmin);
  /*@ assert \valid(pmin); */
  {
    int __gen_e_acsl_initialized_3;
    int __gen_e_acsl_and_3;
    __gen_e_acsl_initialized_3 = __e_acsl_initialized((void *)(& pmin),
                                                      sizeof(char *));
    if (__gen_e_acsl_initialized_3) {
      int __gen_e_acsl_valid_5;
      __gen_e_acsl_valid_5 = __e_acsl_valid((void *)pmin,sizeof(char),
                                            (void *)pmin,(void *)(& pmin));
      __gen_e_acsl_and_3 = __gen_e_acsl_valid_5;
    }
    else __gen_e_acsl_and_3 = 0;
    __e_acsl_assert(__gen_e_acsl_and_3,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(pmin)",49);
  }
  /*@ assert \valid(pmax); */
  {
    int __gen_e_acsl_initialized_4;
    int __gen_e_acsl_and_4;
    __gen_e_acsl_initialized_4 = __e_acsl_initialized((void *)(& pmax),
                                                      sizeof(char *));
    if (__gen_e_acsl_initialized_4) {
      int __gen_e_acsl_valid_6;
      __gen_e_acsl_valid_6 = __e_acsl_valid((void *)pmax,sizeof(char),
                                            (void *)pmax,(void *)(& pmax));
      __gen_e_acsl_and_4 = __gen_e_acsl_valid_6;
    }
    else __gen_e_acsl_and_4 = 0;
    __e_acsl_assert(__gen_e_acsl_and_4,(char *)"Assertion",(char *)"main",
                    (char *)"\\valid(pmax)",50);
  }
  /*@ assert ¬\valid(pmin + diff); */
  {
    int __gen_e_acsl_valid_7;
    __gen_e_acsl_valid_7 = __e_acsl_valid((void *)(pmin + diff),sizeof(char),
                                          (void *)pmin,(void *)(& pmin));
    __e_acsl_assert(! __gen_e_acsl_valid_7,(char *)"Assertion",
                    (char *)"main",(char *)"!\\valid(pmin + diff)",52);
  }
  /*@ assert ¬\valid(pmax - diff); */
  {
    int __gen_e_acsl_valid_8;
    __gen_e_acsl_valid_8 = __e_acsl_valid((void *)(pmax - diff),sizeof(char),
                                          (void *)pmax,(void *)(& pmax));
    __e_acsl_assert(! __gen_e_acsl_valid_8,(char *)"Assertion",
                    (char *)"main",(char *)"!\\valid(pmax - diff)",54);
  }
  __retres = 0;
  __e_acsl_delete_block((void *)(& B));
  __e_acsl_delete_block((void *)(& pmax));
  __e_acsl_delete_block((void *)(& pmin));
  __e_acsl_delete_block((void *)(& b));
  __e_acsl_delete_block((void *)(& p));
  __e_acsl_memory_clean();
  return __retres;
}


