/**************************************************************************/
/*                                                                        */
/*  This file is part of the Frama-C's E-ACSL plug-in.                    */
/*                                                                        */
/*  Copyright (C) 2012-2018                                               */
/*    CEA (Commissariat à l'énergie atomique et aux énergies              */
/*         alternatives)                                                  */
/*                                                                        */
/*  you can redistribute it and/or modify it under the terms of the GNU   */
/*  Lesser General Public License as published by the Free Software       */
/*  Foundation, version 2.1.                                              */
/*                                                                        */
/*  It is distributed in the hope that it will be useful,                 */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of        */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         */
/*  GNU Lesser General Public License for more details.                   */
/*                                                                        */
/*  See the GNU Lesser General Public License version 2.1                 */
/*  for more details (enclosed in the file licenses/LGPLv2.1).            */
/*                                                                        */
/**************************************************************************/

/*! ***********************************************************************
 * \file  e_acsl_temporal_timestamp.h
 * \brief Generating temporal timestamps
***************************************************************************/

#ifndef E_ACSL_TEMPORAL_TIMESTAMP_H /*{{{*/
#define E_ACSL_TEMPORAL_TIMESTAMP_H

#include <stdint.h>

#ifdef E_ACSL_TEMPORAL /*{{{*/
/*! Temporal time stamp generator variable
 * Time stamp is generated by incrementing `temporal_timestamp` variable.
 * Value distribution is as follows:
 *  `0` - invalid time stamp, i.e., a pointer carrying the referent of 0 does
 *      not point to anything
 *  `1` - timestamp associated with global variables, i.e., each global variable
 *      has allocation time stamp of '1'
 *  `>1` - heap or stack blocks allocated during a program's execution */
static uint32_t temporal_timestamp = 2;

#define INVALID_TEMPORAL_TIMESTAMP 0
#define GLOBAL_TEMPORAL_TIMESTAMP 1
#define NEW_TEMPORAL_TIMESTAMP() (++temporal_timestamp)

/*! Maximal number of parameters a function can accept
 * [ C99, 5.2.4.1 Translation Limits ] */
#define MAX_PARAMETERS 127

struct temporal_parameter {
  void *ptr;
  /* Number all members such that there is no `0` which potentially
     corresponds to an invalid number */
  enum {
    TBlockN = 10,
    TReferentN  = 20,
    TCopy = 30
  } temporal_flow;
};

typedef struct temporal_parameter temporal_parameter;

/*! \brief External array used to transfer parameters from one function
 * to another.
 *
 * WARNING! NOT thread-safe! A better way would probably have it as
 * __thread so it is local to every thread. */
static temporal_parameter parameter_referents[MAX_PARAMETERS];
static uint32_t return_referent;

#define reset_parameter_referents() \
  memset(parameter_referents, 0, sizeof(parameter_referents))

#endif /*}}} E_ACSL_TEMPORAL */
#endif /*}}} E_ACSL_TEMPORAL_TIMESTAMP */