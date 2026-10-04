# Read by every zsh through ZDOTDIR: records each executed line as file:line to $COV_LOG.
# zsh has no BASH_XTRACEFD, so a DEBUG trap writes the log instead of xtrace.
# See docs/design/coverage-and-mutation.md
if [[ -n ${COV_LOG:-} ]]; then
  zmodload zsh/parameter
  TRAPDEBUG() { print -r -- "+${funcfiletrace[1]}" >>$COV_LOG }
fi
