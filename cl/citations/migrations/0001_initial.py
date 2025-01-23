# Generated by Django 5.1.4 on 2025-01-23 22:48

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ("search", "0037_alter_citation_type_noop"),
    ]

    operations = [
        migrations.CreateModel(
            name="UnmatchedCitation",
            fields=[
                (
                    "id",
                    models.AutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                (
                    "volume",
                    models.SmallIntegerField(
                        help_text="The volume of the reporter"
                    ),
                ),
                (
                    "reporter",
                    models.TextField(
                        db_index=True,
                        help_text="The abbreviation for the reporter",
                    ),
                ),
                (
                    "page",
                    models.TextField(
                        help_text="The 'page' of the citation in the reporter. Unfortunately, this is not an integer, but is a string-type because several jurisdictions do funny things with the so-called 'page'. For example, we have seen Roman numerals in Nebraska, 13301-M in Connecticut, and 144M in Montana."
                    ),
                ),
                (
                    "type",
                    models.SmallIntegerField(
                        choices=[
                            (1, "A federal reporter citation (e.g. 5 F. 55)"),
                            (
                                2,
                                "A citation in a state-based reporter (e.g. Alabama Reports)",
                            ),
                            (
                                3,
                                "A citation in a regional reporter (e.g. Atlantic Reporter)",
                            ),
                            (
                                4,
                                "A citation in a specialty reporter (e.g. Lawyers' Edition)",
                            ),
                            (
                                5,
                                "A citation in an early SCOTUS reporter (e.g. 5 Black. 55)",
                            ),
                            (
                                6,
                                "A citation in the Lexis system (e.g. 5 LEXIS 55)",
                            ),
                            (
                                7,
                                "A citation in the WestLaw system (e.g. 5 WL 55)",
                            ),
                            (8, "A vendor neutral citation (e.g. 2013 FL 1)"),
                            (
                                9,
                                "A law journal citation within a scholarly or professional legal periodical (e.g. 95 Yale L.J. 5; 72 Soc.Sec.Rep.Serv. 318)",
                            ),
                        ],
                        help_text="The type of citation that this is.",
                    ),
                ),
                (
                    "status",
                    models.SmallIntegerField(
                        choices=[
                            (
                                1,
                                "The citation may be unmatched if: 1. it does not exist in the search_citation table. 2. It exists on the search_citation table, but we couldn't match the citation to a cluster on the previous citation extractor run",
                            ),
                            (
                                2,
                                "The citation exists on the search_citation table. We  haven't updated the citing Opinion.html_with_citations yet",
                            ),
                            (
                                3,
                                "The citing Opinion.html_with_citations was updated successfully",
                            ),
                            (
                                4,
                                "The citing Opinion.html_with_citations update failed because the citation is ambiguous",
                            ),
                            (
                                5,
                                "We couldn't resolve the citation, and the citing Opinion.html_with_citations update failed",
                            ),
                        ],
                        help_text="Status of resolution of the initially unmatched citation",
                    ),
                ),
                (
                    "citation_string",
                    models.TextField(
                        help_text="The unparsed citation string in case it doesn't match the regular citation model in BaseCitation"
                    ),
                ),
                (
                    "court_id",
                    models.TextField(
                        help_text="A court_id as identified by eyecite from the opinion's context. May be useful to know where to find missing citations"
                    ),
                ),
                (
                    "year",
                    models.SmallIntegerField(
                        help_text="A year identified by eyecite from the opinion's context",
                        null=True,
                    ),
                ),
                (
                    "citing_opinion",
                    models.ForeignKey(
                        help_text="The opinion citing this citation",
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="unmatched_citations",
                        to="search.opinion",
                    ),
                ),
            ],
            options={
                "indexes": [
                    models.Index(
                        fields=["volume", "reporter", "page"],
                        name="citations_u_volume_da4d25_idx",
                    )
                ],
                "unique_together": {
                    ("citing_opinion", "volume", "reporter", "page")
                },
            },
        ),
    ]
