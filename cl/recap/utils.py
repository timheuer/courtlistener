from django.core.files.base import ContentFile
from django.db.models import QuerySet

from cl.corpus_importer.utils import ais_appellate_court, is_appellate_court
from cl.recap.models import UPLOAD_TYPE, ProcessingQueue
from cl.search.models import RECAPDocument


def get_main_rds(court_id: str, pacer_doc_id: str) -> QuerySet:
    """
    Return the main RECAPDocument queryset for a given court and pacer_doc_id.
    :param court_id: The court ID to query.
    :param pacer_doc_id: The pacer document ID.
    :return: The main RECAPDocument queryset.
    """
    main_rds_qs = (
        RECAPDocument.objects.select_related("docket_entry__docket")
        .filter(
            pacer_doc_id=pacer_doc_id,
            docket_entry__docket__court_id=court_id,
        )
        .order_by("docket_entry__docket__pacer_case_id")
        .distinct("docket_entry__docket__pacer_case_id")
        .only(
            "pacer_doc_id",
            "docket_entry__docket__pacer_case_id",
            "docket_entry__docket__court_id",
        )
    )
    return main_rds_qs


def find_subdocket_pdf_rds_from_data(
    user_id, court_id, pacer_doc_id, pacer_case_ids, pdf_bytes
):

    # Logic to replicate the PDF sub-dockets matched by RECAPDocument
    sub_docket_main_rds = list(
        get_main_rds(court_id, pacer_doc_id).exclude(
            docket_entry__docket__pacer_case_id__in=pacer_case_ids
        )
    )

    sub_docket_pqs = []
    for main_rd in sub_docket_main_rds:
        # Create PQs related to RD that require replication.
        sub_docket_pqs.append(
            ProcessingQueue(
                uploader_id=user_id,
                pacer_doc_id=main_rd.pacer_doc_id,
                pacer_case_id=main_rd.docket_entry.docket.pacer_case_id,
                document_number=main_rd.document_number,
                attachment_number=main_rd.attachment_number,
                court_id=court_id,
                upload_type=UPLOAD_TYPE.PDF,
                filepath_local=ContentFile(pdf_bytes, name="document.pdf"),
            )
        )

    if not sub_docket_pqs:
        return []

    return ProcessingQueue.objects.bulk_create(sub_docket_pqs)


def find_subdocket_atts_rds_from_data(
    user_id, court_id, pacer_doc_id, pacer_case_ids, att_bytes
):

    # Logic to replicate the PDF sub-dockets matched by RECAPDocument
    sub_docket_main_rds = list(
        get_main_rds(court_id, pacer_doc_id).exclude(
            docket_entry__docket__pacer_case_id__in=pacer_case_ids
        )
    )

    sub_docket_pqs = []
    for main_rd in sub_docket_main_rds:
        # Create PQs related to RD that require replication.
        sub_docket_pqs.append(
            ProcessingQueue(
                uploader_id=user_id,
                pacer_doc_id=main_rd.pacer_doc_id,
                pacer_case_id=main_rd.docket_entry.docket.pacer_case_id,
                court_id=court_id,
                upload_type=UPLOAD_TYPE.ATTACHMENT_PAGE,
                filepath_local=ContentFile(
                    att_bytes, name="attachment_page.html"
                ),
            )
        )

    if not sub_docket_pqs:
        return []

    return ProcessingQueue.objects.bulk_create(sub_docket_pqs)
