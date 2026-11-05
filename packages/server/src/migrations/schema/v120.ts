// SPDX-FileCopyrightText: Copyright Orangebot, Inc. and Medplum contributors
// SPDX-License-Identifier: Apache-2.0
/*
 * This is a generated file
 * Do not edit manually.
 */

import type { PoolClient } from 'pg';
import * as fns from '../migrate-functions';

// prettier-ignore
export async function run(client: PoolClient): Promise<void> {
  const results: { name: string; durationMs: number }[] = []
  await fns.query(client, results, `CREATE OR REPLACE FUNCTION token_array_to_text(text[])
    RETURNS text LANGUAGE sql IMMUTABLE
    AS $function$SELECT e'\x03'||array_to_string($1, e'\x03')||e'\x03'$function$`);
}
