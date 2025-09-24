# post‑deploy configuration (entra, graph, key vault, cors)

## app registration (obo)
- Client Id: 170c98e1-d486-4355-bcbe-170454e0207c (tenant a221a95e-6abc-4434-aecc-e48338a1b2f2)
- Expose scope: access_as_user
- Add delegated Graph permissions for SharePoint Embedded / FileStorage; admin consent.

## key vault
- Name: spaarke-spekvcert
- Set secret 'AzureAd--ClientSecret' (use scripts/kv_set_secret.sh).

## web app app settings
- Name: spaarke-spe-bff-dev, RG: SharePointEmbedded
- Set via scripts/appsettings_set.sh with Key Vault secret URI.
