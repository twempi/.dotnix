{
  sops.secrets.anki_sync_key = {
    sopsFile = ../../../../secrets/anki.yaml;
    owner = "edward";
    mode = "0400";
  };
}
