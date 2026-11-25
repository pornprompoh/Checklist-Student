/// Local datasource interface placeholder for `features/student_portal/`
/// following the 3-layer Clean Architecture template.
///
/// Student Portal reads live server-masked data through `SECURITY DEFINER`
/// RPCs and intentionally does not cache sensitive student data offline.
abstract interface class StudentPortalLocalDataSource {}
