import string
from datetime import date

from factory import (
    Faker,
    LazyAttribute,
    RelatedFactory,
    SelfAttribute,
    SubFactory,
)
from factory.django import DjangoModelFactory, FileField
from factory.fuzzy import FuzzyChoice, FuzzyText
from juriscraper.lib.string_utils import CaseNameTweaker

from cl.people_db.factories import PersonFactory
from cl.search.models import (
    DOCUMENT_STATUSES,
    SOURCES,
    Citation,
    Court,
    Docket,
    DocketEntry,
    Opinion,
    OpinionCluster,
    Parenthetical,
)
from cl.tests.providers import LegalProvider

Faker.add_provider(LegalProvider)

cnt = CaseNameTweaker()


class CourtFactory(DjangoModelFactory):
    class Meta:
        model = Court
        django_get_or_create = ("id",)

    id = FuzzyText(length=4, chars=string.ascii_lowercase, suffix="d")
    position = Faker("pyfloat", positive=True, right_digits=4, left_digits=3)
    short_name = Faker("court_name")
    full_name = Faker("court_name")
    url = Faker("url")
    jurisdiction = FuzzyChoice(Court.JURISDICTIONS, getter=lambda c: c[0])
    in_use = True


class ParentheticalFactory(DjangoModelFactory):
    class Meta:
        model = Parenthetical

    describing_opinion = SelfAttribute("described_opinion")
    text = Faker("sentence")
    score = Faker("pyfloat", min_value=0, max_value=1, right_digits=4)


class ParentheticalWithParentsFactory(ParentheticalFactory):
    describing_opinion = SubFactory(
        "cl.search.factories.OpinionWithParentsFactory",
    )
    described_opinion = SelfAttribute("describing_opinion")


class OpinionFactory(DjangoModelFactory):
    class Meta:
        model = Opinion

    author = SubFactory(PersonFactory)
    author_str = LazyAttribute(lambda self: self.author.name_full)
    type = FuzzyChoice(Opinion.OPINION_TYPES, getter=lambda c: c[0])
    sha1 = Faker("sha1")
    plain_text = Faker("text", max_nb_chars=2000)


class OpinionWithChildrenFactory(OpinionFactory):

    parentheticals = RelatedFactory(
        ParentheticalFactory,
        factory_related_name="described_opinion",
    )


class CitationFactory(DjangoModelFactory):
    class Meta:
        model = Citation

    volume = Faker("random_int", min=1, max=100)
    reporter = "U.S."
    page = Faker("random_int", min=1, max=100)
    type = 1


class CitationWithParentsFactory(CitationFactory):
    class Params:
        case_name = Faker("case_name")
        date_filed = Faker(
            "date_between", start_date=date(1876, 1, 1), end_date=date.today()
        )
        plain_text = Faker("text", max_nb_chars=2000)
        court_id = FuzzyText(
            length=4, chars=string.ascii_lowercase, suffix="d"
        )

    cluster = SubFactory(
        "cl.search.factories.OpinionClusterFactoryForCitation",
        case_name=SelfAttribute("..case_name"),
        date_filed=SelfAttribute("..date_filed"),
        plain_text=SelfAttribute("..plain_text"),
        court_id=SelfAttribute("..court_id"),
    )


class OpinionWithParentsFactory(OpinionFactory):
    cluster = SubFactory(
        "cl.search.factories.OpinionClusterWithParentsFactory",
    )


class OpinionClusterFactory(DjangoModelFactory):
    class Meta:
        model = OpinionCluster

    case_name_short = LazyAttribute(
        lambda self: cnt.make_case_name_short(self.case_name)
    )
    case_name = Faker("case_name")
    case_name_full = Faker("case_name", full=True)
    date_filed = Faker("date")
    slug = Faker("slug")
    source = FuzzyChoice(SOURCES, getter=lambda c: c[0])
    precedential_status = FuzzyChoice(DOCUMENT_STATUSES, getter=lambda c: c[0])


class OpinionClusterFactoryWithChildren(OpinionClusterFactory):
    sub_opinions = RelatedFactory(
        OpinionWithChildrenFactory,
        factory_related_name="cluster",
    )


class DocketParentMixin(DjangoModelFactory):
    class Params:
        court_id = FuzzyText(
            length=4, chars=string.ascii_lowercase, suffix="d"
        )

    docket = SubFactory(
        "cl.search.factories.DocketFactory",
        # Set the case names on the docket to the ones on this object
        # if it has them. Else generate the case name values.
        case_name=LazyAttribute(
            lambda self: getattr(
                self.factory_parent,
                "case_name",
                str(Faker("case_name")),
            )
        ),
        case_name_short=LazyAttribute(
            lambda self: getattr(
                self.factory_parent,
                "case_name_short",
                cnt.make_case_name_short(self.case_name),
            )
        ),
        case_name_full=LazyAttribute(
            lambda self: getattr(
                self.factory_parent,
                "case_name_full",
                str(Faker("case_name", full=True)),
            )
        ),
        court_id=SelfAttribute("..court_id"),
    )


class OpinionClusterFactoryForCitation(
    OpinionClusterFactory, DocketParentMixin
):
    class Params:
        plain_text = Faker("text", max_nb_chars=2000)

    # For OpinionClusterFactory
    sub_opinions = RelatedFactory(
        OpinionWithChildrenFactory,
        factory_related_name="cluster",
        plain_text=SelfAttribute("..plain_text"),
    )
    precedential_status = ("Published", "Precedential")  # Always precedential


class OpinionClusterWithParentsFactory(
    OpinionClusterFactory,
    DocketParentMixin,
):
    """Make an OpinionCluster with Docket parents"""

    pass


class DocketEntryFactory(DjangoModelFactory):
    class Meta:
        model = DocketEntry

    description = Faker("text", max_nb_chars=750)


class DocketEntryWithParentsFactory(
    DocketEntryFactory,
    DocketParentMixin,
):
    """Make a DocketEntry with Docket parents"""

    pass


class DocketFactory(DjangoModelFactory):
    class Meta:
        model = Docket

    class Params:
        court_id = FuzzyText(
            length=4, chars=string.ascii_lowercase, suffix="d"
        )

    idb_data = RelatedFactory(
        "cl.recap.factories.FjcIntegratedDatabaseFactory",
        factory_related_name="docket",
    )
    source = FuzzyChoice(Docket.SOURCE_CHOICES, getter=lambda c: c[0])
    court = SubFactory(CourtFactory, id=SelfAttribute("..court_id"))
    appeal_from = SubFactory(CourtFactory)
    case_name_short = LazyAttribute(
        lambda self: cnt.make_case_name_short(self.case_name)
    )
    case_name = Faker("case_name")
    case_name_full = Faker("case_name", full=True)
    pacer_case_id = Faker("pyint", min_value=100_000, max_value=400_000)
    docket_number = Faker("federal_district_docket_number")
    slug = Faker("slug")
    filepath_local = FileField(filename=None)
    date_argued = Faker("date_object")


class DocketWithChildrenFactory(DocketFactory):
    clusters = RelatedFactory(
        OpinionClusterFactoryWithChildren,
        factory_related_name="docket",
    )
