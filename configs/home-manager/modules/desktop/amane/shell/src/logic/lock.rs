use amane::Lock;

// `amane ipc call lock`, from the power menu
pub fn lock(_: &[String]) -> String {
    Lock::start();

    String::from("locked")
}
