;;; xquery-mode-test.el --- xquery-mode test suite

;;; Commentary:

;;; Code:

(define-indent-test function-body-first-line ()
  "Indent first line of function body."
  "
declare function local:get-provider-group-membership($mpf-provider as element(provider))
{
				(for $group-membership in $mpf-provider/provider-group-membership
" "
declare function local:get-provider-group-membership($mpf-provider as element(provider))
{
  (for $group-membership in $mpf-provider/provider-group-membership
")

(define-indent-test flwor-expression-in-brackets ()
  "Indent FLWOR excression within square brackets."
  "
(for $group-membership in $mpf-provider/provider-group-membership
				order by $group-membership/group-membership-effective-date descending
" "
(for $group-membership in $mpf-provider/provider-group-membership
 order by $group-membership/group-membership-effective-date descending
 ")

(define-indent-test flwor-expression-keyword-on-next-line ()
  "Indent line started with RETURN keyword to same column as previous line started with ORDER BY."
  "
								order by $group-membership/group-membership-effective-date descending
								return $group-membership)[1]
" "
order by $group-membership/group-membership-effective-date descending
return $group-membership)[1]
")

(define-indent-test inner-xml-tag ()
  "Inner XML tags should indent with nesting."
  "
<html>
<head>
<title>Access points with an Organization TPI</title>
" "
<html>
  <head>
    <title>Access points with an Organization TPI</title>
")

(define-indent-test sequential-xml-tag ()
  "Sequential XML tags must have same indentation column."
  "
<title>Access points with an Organization TPI</title>
<style type=\"text/css\">
" "
<title>Access points with an Organization TPI</title>
<style type=\"text/css\">
")

(define-indent-test xml-tag-value ()
  "Indent XML tag value differ then opening tag."
  "
<foo>
baz
</foo>" "
<foo>
  baz
</foo>")

(define-indent-test flwor-expression-open-bracket ()
  "Indent FLWOR open curly bracket one level dipper."
  "
<tbody>
{
	for $tpi in fn:subsequence()
" "
<tbody>
  {
    for $tpi in fn:subsequence()
")

(define-indent-test flwor-for-let-let-sequential ()
  "Indent for let lest sequential expression to same column."
  "
{
	for $tpi in fn:subsequence()
	let $provider-id := $tpi/../../provider
	let $facility := $tpi/../../..
" "
{
  for $tpi in fn:subsequence()
  let $provider-id := $tpi/../../provider
  let $facility := $tpi/../../..
")

(define-indent-test flwor-let-order-by-sequential ()
  "Indent sequential let order by statements to the same column."
  "
{
	for $tpi in fn:subsequence()
	let $provider-id := $tpi/../../provider
	order by $provider-id/id
" "
{
  for $tpi in fn:subsequence()
  let $provider-id := $tpi/../../provider
  order by $provider-id/id
")

(define-indent-test flwor-return-let-let-nested ()
  "Indent let statement nested into return statement with dipper column."
  "
return
let $mpf-provider := doc()/provider
let $group-tpi := local:get-provider-group-membership()
" "
return
  let $mpf-provider := doc()/provider
  let $group-tpi := local:get-provider-group-membership()
")

(provide 'xquery-mode-test)

;;; xquery-mode-test.el ends here
