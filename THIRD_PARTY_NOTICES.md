# Third-party material and public-release review

The root MIT license covers original X-hale code and documentation Stefanos Theos owns and is authorized to license. It does not grant rights in third-party material. Dependency licenses and original rights-holder terms continue to apply.

The tracked tree does not yet contain a complete asset-provenance register:

| Material | Location | Review required before public release |
| --- | --- | --- |
| Cal Sans and Comfortaa | `fonts/CalSans-Regular.ttf`, `fonts/Comfortaa-*.ttf` | Embedded font metadata declares SIL OFL 1.1. Upstream notices matching the embedded copyright declarations are retained in `fonts/licenses/`; see its README. These fonts are not MIT. |
| Star Jedi font | `fonts/starjedi.ttf` | Embedded metadata names Boba Fonts/Davide Canavero but supplies no license grant. Obtain the applicable terms or replace the font before public release. |
| Icons, illustrations, game graphics and audio | `assets/` | Record sources, creators and redistribution terms for externally sourced families; identify original artwork separately. Preserve build-required assets while treatment is decided. |
| Branding | Service/institution marks where present locally or in history | Check brand/trademark conditions. A software license does not grant trademark rights. |
| Legacy reference PDFs | `rag_backend/resources/pdfs/` | Four PDFs lack an accompanying redistribution record. The Tombor paper includes an Elsevier all-rights-reserved notice; the Matos paper identifies an exclusive Springer Nature license. Resolve permissions or replace bundled copies with source references before public release. The other two files also require source-specific review. |
| Legacy extracted text | `rag_backend/resources/text/` | Ten files need source, attribution and redistribution records. Use source links/ingestion instructions instead of copies where required. |
| Active knowledge content | `rag_backend2.0/ingestion/sources.yaml` and fetched snapshots | Follow the governance procedure and source-specific terms. A manifest entry is not a redistribution license. |

For each retained third-party asset, record the path, creator, original URL, exact license/version, attribution, modifications and review outcome. Include license texts where required. Do not label these assets MIT merely because a root MIT license exists.

This inventory identifies unresolved release work; it does not determine that any particular use is unlawful or that redistribution has been cleared. Review historical copies as well as the final tree before changing visibility. See [the roadmap](docs/ROADMAP.md).
