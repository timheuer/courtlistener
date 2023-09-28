#!/bin/bash
set -e

echo "Installing utilities"

# Set up Sentry
curl -sL https://sentry.io/get-cli/ | bash
eval "$(sentry-cli bash-hook)"

# Set up AWS tools and gnupg (needed for apt-key add, below)
apt install -y awscli gnupg

# Install latest version of pg_dump (else we get an error about version mismatch
echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl --silent 'https://www.postgresql.org/media/keys/ACCC4CF8.asc' |  apt-key add -
apt-get update
apt-get install -y postgresql-client

# Stream to S3

echo "Streaming search_court to S3"
court_fields='(
	       id, pacer_court_id, pacer_has_rss_feed, pacer_rss_entry_types, date_last_pacer_contact,
	       fjc_court_id, date_modified, in_use, has_opinion_scraper,
	       has_oral_argument_scraper, position, citation_string, short_name, full_name,
	       url, start_date, end_date, jurisdiction, notes, parent_court_id
	       )'
court_csv_filename="courts-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_court $court_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$court_csv_filename".bz2 --acl public-read

echo "Streaming search_courthouse to S3"
courthouse_fields='(id, court_seat, building_name, address1, address2, city, county,
state, zip_code, country_code, court_id)'
courthouse_csv_filename="courthouses-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_courthouse $courthouse_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$courthouse_csv_filename".bz2 --acl public-read

# Through table for courts m2m field: appeals_to
echo "Streaming search_court_appeals_to to S3"
court_appeals_to_fields='(id, from_court_id, to_court_id)'
court_appeals_to_csv_filename="court-appeals-to-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_court_appeals_to $court_appeals_to_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$court_appeals_to_csv_filename".bz2 --acl public-read

echo "Streaming search_docket to S3"
docket_fields='(id, date_created, date_modified, source, appeal_from_str,
	       assigned_to_str, referred_to_str, panel_str, date_last_index, date_cert_granted,
	       date_cert_denied, date_argued, date_reargued,
	       date_reargument_denied, date_filed, date_terminated,
	       date_last_filing, case_name_short, case_name, case_name_full, slug,
	       docket_number, docket_number_core, pacer_case_id, cause,
	       nature_of_suit, jury_demand, jurisdiction_type,
	       appellate_fee_status, appellate_case_type_information, mdl_status,
	       filepath_local, filepath_ia, filepath_ia_json, ia_upload_failure_count, ia_needs_upload,
	       ia_date_first_change, view_count, date_blocked, blocked, appeal_from_id, assigned_to_id,
	       court_id, idb_data_id, originating_court_information_id, referred_to_id
	       )'
dockets_csv_filename="dockets-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_docket $docket_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$dockets_csv_filename".bz2 --acl public-read

echo "Streaming search_originatingcourtinformation to S3"
originatingcourtinformation_fields='(
	       id, date_created, date_modified, docket_number, assigned_to_str,
	       ordering_judge_str, court_reporter, date_disposed, date_filed, date_judgment,
	       date_judgment_eod, date_filed_noa, date_received_coa, assigned_to_id,
	       ordering_judge_id
	       )'
originatingcourtinformation_csv_filename="originating-court-information-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_originatingcourtinformation $originatingcourtinformation_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$originatingcourtinformation_csv_filename".bz2 --acl public-read

echo "Streaming recap_fjcintegrateddatabase to S3"
fjcintegrateddatabase_fields='(
	       id, date_created, date_modified, dataset_source, office,
	       docket_number, origin, date_filed, jurisdiction, nature_of_suit,
	       title, section, subsection, diversity_of_residence, class_action,
	       monetary_demand, county_of_residence, arbitration_at_filing,
	       arbitration_at_termination, multidistrict_litigation_docket_number,
	       plaintiff, defendant, date_transfer, transfer_office,
	       transfer_docket_number, transfer_origin, date_terminated,
	       termination_class_action_status, procedural_progress, disposition,
	       nature_of_judgement, amount_received, judgment, pro_se,
	       year_of_tape, nature_of_offense, version, circuit_id, district_id
	   )'
fjcintegrateddatabase_csv_filename="fjc-integrated-database-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY recap_fjcintegrateddatabase $fjcintegrateddatabase_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$fjcintegrateddatabase_csv_filename".bz2 --acl public-read

echo "Streaming search_opinioncluster to S3"
opinioncluster_fields='(
	       id, date_created, date_modified, judges, date_filed,
	       date_filed_is_approximate, slug, case_name_short, case_name,
	       case_name_full, scdb_id, scdb_decision_direction, scdb_votes_majority,
	       scdb_votes_minority, source, procedural_history, attorneys,
	       nature_of_suit, posture, syllabus, headnotes, summary, disposition,
	       history, other_dates, cross_reference, correction, citation_count,
	       precedential_status, date_blocked, blocked, filepath_json_harvard, docket_id,
	       arguments, headmatter
	   )'
opinioncluster_csv_filename="opinion-clusters-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_opinioncluster $opinioncluster_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$opinioncluster_csv_filename".bz2 --acl public-read

echo "Streaming search_opinion to S3"
opinion_fields='(
	       id, date_created, date_modified, author_str, per_curiam, joined_by_str,
	       type, sha1, page_count, download_url, local_path, plain_text, html,
	       html_lawbox, html_columbia, html_anon_2020, xml_harvard,
	       html_with_citations, extracted_by_ocr, author_id, cluster_id
	   )'
opinions_csv_filename="opinions-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_opinion $opinion_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$opinions_csv_filename".bz2 --acl public-read

echo "Streaming search_opinionscited to S3"
opinionscited_fields='(
	       id, depth, cited_opinion_id, citing_opinion_id
	   )'
opinionscited_csv_filename="citation-map-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_opinionscited $opinionscited_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$opinionscited_csv_filename".bz2 --acl public-read

echo "Streaming search_citation to S3"
citation_fields='(
	       id, volume, reporter, page, type, cluster_id
	   )'
citations_csv_filename="citations-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_citation $citation_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$citations_csv_filename".bz2 --acl public-read

echo "Streaming search_parenthetical to S3"
parentheticals_fields='(
	       id, text, score, described_opinion_id, describing_opinion_id, group_id
	   )'
parentheticals_csv_filename="parentheticals-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY search_parenthetical $parentheticals_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$parentheticals_csv_filename".bz2 --acl public-read

echo "Streaming audio_audio to S3"
oralarguments_fields='(
	       id, date_created, date_modified, source, case_name_short,
	       case_name, case_name_full, judges, sha1, download_url, local_path_mp3,
	       local_path_original_file, filepath_ia, ia_upload_failure_count, duration,
	       processing_complete, date_blocked, blocked, stt_status, stt_google_response,
	       docket_id
	   )'
oralarguments_csv_filename="oral-arguments-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY audio_audio $oralarguments_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$oralarguments_csv_filename".bz2 --acl public-read

echo "Streaming people_db_person to S3"
people_db_person_fields='(
	       id, date_created, date_modified, date_completed, fjc_id, slug, name_first,
	       name_middle, name_last, name_suffix, date_dob, date_granularity_dob,
	       date_dod, date_granularity_dod, dob_city, dob_state, dob_country,
	       dod_city, dod_state, dod_country, gender, religion, ftm_total_received,
	       ftm_eid, has_photo, is_alias_of_id
	   )'
people_db_person_csv_filename="people-db-people-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY people_db_person $people_db_person_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$people_db_person_csv_filename".bz2 --acl public-read

echo "Streaming people_db_school to S3"
people_db_school_fields='(
	       id, date_created, date_modified, name, ein, is_alias_of_id
	   )'
people_db_school_csv_filename="people-db-schools-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY people_db_school $people_db_school_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$people_db_school_csv_filename".bz2 --acl public-read

echo "Streaming people_db_position to S3"
people_db_position_fields='(
	       id, date_created, date_modified, position_type, job_title,
	       sector, organization_name, location_city, location_state,
	       date_nominated, date_elected, date_recess_appointment,
	       date_referred_to_judicial_committee, date_judicial_committee_action,
	       judicial_committee_action, date_hearing, date_confirmation, date_start,
	       date_granularity_start, date_termination, termination_reason,
	       date_granularity_termination, date_retirement, nomination_process, vote_type,
	       voice_vote, votes_yes, votes_no, votes_yes_percent, votes_no_percent, how_selected,
	       has_inferred_values, appointer_id, court_id, person_id, predecessor_id, school_id,
	       supervisor_id
	   )'
people_db_position_csv_filename="people-db-positions-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY people_db_position $people_db_position_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$people_db_position_csv_filename".bz2 --acl public-read

echo "Streaming people_db_retentionevent to S3"
people_db_retentionevent_fields='(
	       id, date_created, date_modified, retention_type, date_retention,
	       votes_yes, votes_no, votes_yes_percent, votes_no_percent, unopposed,
	       won, position_id
	   )'
people_db_retentionevent_csv_filename="people-db-retention-events-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY people_db_retentionevent $people_db_retentionevent_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$people_db_retentionevent_csv_filename".bz2 --acl public-read

echo "Streaming people_db_education to S3"
people_db_education_fields='(
	       id, date_created, date_modified, degree_level, degree_detail,
	       degree_year, person_id, school_id
	   )'
people_db_education_csv_filename="people-db-educations-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY people_db_education $people_db_education_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$people_db_education_csv_filename".bz2 --acl public-read

echo "Streaming people_db_politicalaffiliation to S3"
politicalaffiliation_fields='(
	       id, date_created, date_modified, political_party, source,
	       date_start, date_granularity_start, date_end,
	       date_granularity_end, person_id
	   )'
politicalaffiliation_csv_filename="people-db-political-affiliations-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY people_db_politicalaffiliation $politicalaffiliation_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$politicalaffiliation_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_financialdisclosure to S3"
financialdisclosure_fields='(
	       id, date_created, date_modified, year, download_filepath, filepath, thumbnail,
	       thumbnail_status, page_count, sha1, report_type, is_amended, addendum_content_raw,
	       addendum_redacted, has_been_extracted, person_id
	   )'
financialdisclosure_csv_filename="financial-disclosures-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_financialdisclosure $financialdisclosure_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$financialdisclosure_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_investment to S3"
investment_fields='(
	       id, date_created, date_modified, page_number, description, redacted,
	       income_during_reporting_period_code, income_during_reporting_period_type,
	       gross_value_code, gross_value_method,
	       transaction_during_reporting_period, transaction_date_raw,
	       transaction_date, transaction_value_code, transaction_gain_code,
	       transaction_partner, has_inferred_values, financial_disclosure_id
	   )'
investment_csv_filename="financial-disclosure-investments-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_investment $investment_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$investment_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_position to S3"
disclosures_position_fields='(
	       id, date_created, date_modified, position, organization_name,
	       redacted, financial_disclosure_id
	   )'
disclosures_position_csv_filename="financial-disclosures-positions-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_position $disclosures_position_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$disclosures_position_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_agreement to S3"
disclosures_agreement_fields='(
	       id, date_created, date_modified, date_raw, parties_and_terms,
	       redacted, financial_disclosure_id
	   )'
disclosures_agreement_csv_filename="financial-disclosures-agreements-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_agreement $disclosures_agreement_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$disclosures_agreement_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_noninvestmentincome to S3"
noninvestmentincome_fields='(
	       id, date_created, date_modified, date_raw, source_type,
	       income_amount, redacted, financial_disclosure_id
	   )'
noninvestmentincome_csv_filename="financial-disclosures-non-investment-income-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_noninvestmentincome $noninvestmentincome_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$noninvestmentincome_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_spouseincome to S3"
spouseincome_fields='(
	       id, date_created, date_modified, source_type, date_raw, redacted,
	       financial_disclosure_id
	   )'
spouseincome_csv_filename="financial-disclosures-spousal-income-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_spouseincome $spouseincome_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$spouseincome_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_reimbursement to S3"
disclosures_reimbursement_fields='(
	       id, date_created, date_modified, source, date_raw, location,
	       purpose, items_paid_or_provided, redacted, financial_disclosure_id
	   )'
disclosures_reimbursement_csv_filename="financial-disclosures-reimbursements-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_reimbursement $disclosures_reimbursement_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$disclosures_reimbursement_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_gift to S3"
disclosures_gift_fields='(
	       id, date_created, date_modified, source, description, value,
	       redacted, financial_disclosure_id
	   )'
disclosures_gift_csv_filename="financial-disclosures-gifts-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_gift $disclosures_gift_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$disclosures_gift_csv_filename".bz2 --acl public-read

echo "Streaming disclosures_debt to S3"
disclosures_debt_fields='(
	       id, date_created, date_modified, creditor_name, description,
	       value_code, redacted, financial_disclosure_id
	   )'
disclosures_debt_csv_filename="financial-disclosures-debts-$(date -I).csv"
PGPASSWORD=$DB_PASSWORD psql \
	--command \
	  "set statement_timeout to 0;
	   COPY disclosures_debt $disclosures_debt_fields TO STDOUT WITH (FORMAT csv, ENCODING utf8, HEADER, FORCE_QUOTE *)" \
	--quiet \
	--host "$DB_HOST" \
	--username "$DB_USER" \
	--dbname courtlistener | \
	bzip2 | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$disclosures_debt_csv_filename".bz2 --acl public-read

echo "Exporting schema to S3"
schema_filename="schema-$(date -I).sql"
PGPASSWORD=$DB_PASSWORD pg_dump \
    --host "$DB_HOST" \
    --username "$DB_USER" \
    --create \
    --schema-only \
    --table 'search_*' \
    --table 'people_db_*' \
    --table 'audio_*' \
    --no-privileges \
    --no-publications \
    --no-subscriptions courtlistener | \
	aws s3 cp - s3://com-courtlistener-storage/bulk-data/"$schema_filename" --acl public-read

echo "Done."
