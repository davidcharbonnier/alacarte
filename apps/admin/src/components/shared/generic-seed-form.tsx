import { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Stack,
  Tab,
  Tabs,
  TextField,
  Typography,
  CircularProgress,
} from '@mui/material';
import ArrowBack from '@mui/icons-material/ArrowBack';
import Upload from '@mui/icons-material/Upload';
import CheckCircle from '@mui/icons-material/CheckCircle';
import Warning from '@mui/icons-material/Warning';
import FileSearch from '@mui/icons-material/Search';
import FileUpload from '@mui/icons-material/FileUpload';
import LinkIcon from '@mui/icons-material/Link';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate, Link } from '@tanstack/react-router';
import { useSchema } from '../../lib/context/schema-context';
import { apiClient } from '../../lib/api/client';

type Source = 'file' | 'url';

interface ValidateResponse {
  valid: boolean;
  errors: string[];
}

interface SeedResponse {
  added: number;
  skipped: number;
  errors: string[];
}

export function GenericSeedForm({ itemType }: { itemType: string }) {
  const { schema, fields } = useSchema(itemType);
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [tab, setTab] = useState<Source>('file');
  const [url, setUrl] = useState('');
  const [urlError, setUrlError] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [fileData, setFileData] = useState<any>(null);
  const [fileError, setFileError] = useState('');
  const [validated, setValidated] = useState(false);

  const validateMutation = useMutation({
    mutationFn: async (payload: { url?: string; data?: any }): Promise<ValidateResponse> => {
      const body = payload.url ? { url: payload.url } : { data: payload.data };
      return apiClient.post<ValidateResponse>(`/admin/items/${itemType}/validate`, body);
    },
    onSuccess: (data) => {
      if (data.valid !== false) setValidated(true);
    },
  });

  const seedMutation = useMutation({
    mutationFn: async (payload: { url?: string; data?: any }): Promise<SeedResponse> => {
      const body = payload.url ? { url: payload.url } : { data: payload.data };
      return apiClient.post<SeedResponse>(`/admin/items/${itemType}/seed`, body);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['items', itemType, 'list'] });
    },
  });

  if (!schema) return <Typography color="text.secondary">Schema not found</Typography>;

  const requiredFields = fields.filter((f) => f.required);
  const exampleJson = {
    items: [
      Object.fromEntries(requiredFields.map((f) => [f.key, `Example ${f.label.toLowerCase()}`])),
    ],
  };

  const handleValidateUrl = (e: React.FormEvent) => {
    e.preventDefault();
    setUrlError('');
    setValidated(false);
    try {
      new URL(url);
    } catch {
      setUrlError('Please enter a valid URL');
      return;
    }
    validateMutation.mutate({ url });
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    setValidated(false);
    setFileError('');
    if (!f) {
      setFile(null);
      setFileData(null);
      return;
    }
    if (!f.name.endsWith('.json')) {
      setFileError('Please select a JSON file');
      return;
    }
    setFile(f);
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        setFileData(JSON.parse(ev.target?.result as string));
      } catch {
        setFileError('Invalid JSON file format');
        setFileData(null);
      }
    };
    reader.readAsText(f);
  };

  const handleSeed = () => {
    seedMutation.mutate(tab === 'url' ? { url } : { data: fileData });
  };

  return (
    <Stack spacing={3}>
      <Stack direction="row" spacing={2} alignItems="center">
        <Button component={Link} to={`/items/${itemType}`} startIcon={<ArrowBack />}>
          Back to {schema.plural_name}
        </Button>
      </Stack>
      <Box>
        <Typography variant="headlineSmall" component="h1" sx={{ mb: 0.5 }}>
          Seed {schema.plural_name} data
        </Typography>
        <Typography variant="bodyMedium" color="onSurfaceVariant">
          Bulk import from a JSON file or remote URL
        </Typography>
      </Box>

      <Box sx={{ maxWidth: 720 }}>
        <Card>
          <CardContent sx={{ p: 3 }}>
            <Typography variant="titleMedium" sx={{ mb: 2 }}>Bulk import</Typography>

            <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 3 }}>
              <Tab value="file" label="Upload file" icon={<FileUpload fontSize="small" />} iconPosition="start" />
              <Tab value="url" label="From URL" icon={<LinkIcon fontSize="small" />} iconPosition="start" />
            </Tabs>

            {tab === 'file' ? (
              <Stack spacing={2}>
                <Box>
                  <Button variant="outlined" component="label" fullWidth size="large">
                    {file ? `Selected: ${file.name}` : 'Choose JSON file'}
                    <input type="file" accept=".json" hidden onChange={handleFileChange} />
                  </Button>
                  {fileError && <Typography variant="bodySmall" color="error" sx={{ mt: 1 }}>{fileError}</Typography>}
                </Box>
                {!validated ? (
                  <Button
                    variant="outlined"
                    onClick={() => validateMutation.mutate({ data: fileData })}
                    disabled={!fileData || validateMutation.isPending}
                    startIcon={validateMutation.isPending ? <CircularProgress size={16} /> : <FileSearch />}
                    size="large"
                  >
                    Validate
                  </Button>
                ) : (
                  <Button
                    variant="contained"
                    onClick={handleSeed}
                    disabled={seedMutation.isPending}
                    startIcon={seedMutation.isPending ? <CircularProgress size={16} color="inherit" /> : <Upload />}
                    size="large"
                  >
                    Import data
                  </Button>
                )}
              </Stack>
            ) : (
              <Stack spacing={2} component="form" onSubmit={handleValidateUrl}>
                <TextField
                  fullWidth
                  label="JSON file URL"
                  placeholder={`https://example.com/${schema.plural_name.toLowerCase()}.json`}
                  value={url}
                  onChange={(e) => {
                    setUrl(e.target.value);
                    setValidated(false);
                    setUrlError('');
                  }}
                  error={!!urlError}
                  helperText={urlError}
                />
                {!validated ? (
                  <Button
                    type="submit"
                    variant="outlined"
                    disabled={!url || validateMutation.isPending}
                    startIcon={validateMutation.isPending ? <CircularProgress size={16} /> : <FileSearch />}
                    size="large"
                  >
                    Validate
                  </Button>
                ) : (
                  <Button
                    type="button"
                    variant="contained"
                    onClick={handleSeed}
                    disabled={seedMutation.isPending}
                    startIcon={seedMutation.isPending ? <CircularProgress size={16} color="inherit" /> : <Upload />}
                    size="large"
                  >
                    Import data
                  </Button>
                )}
              </Stack>
            )}

            <Alert severity="info" icon={<Warning />} sx={{ mt: 3 }}>
              <Typography fontWeight={500}>Expected JSON format</Typography>
              <Box
                component="pre"
                sx={{
                  mt: 1,
                  fontSize: 12,
                  bgcolor: 'surfaceContainer',
                  color: 'onSurface',
                  p: 1.5,
                  borderRadius: '8px',
                  overflow: 'auto',
                  fontFamily: 'monospace',
                }}
              >
                {JSON.stringify(exampleJson, null, 2)}
              </Box>
            </Alert>

            {validateMutation.isSuccess && !validateMutation.data?.valid && (
              <Alert severity="error" sx={{ mt: 2 }}>
                <Typography fontWeight={500}>Validation failed</Typography>
                <Box component="ul" sx={{ mt: 1, pl: 2 }}>
                  {validateMutation.data.errors.map((e, i) => (
                    <li key={i}>{e}</li>
                  ))}
                </Box>
              </Alert>
            )}

            {validated && !seedMutation.isSuccess && (
              <Alert severity="success" icon={<CheckCircle />} sx={{ mt: 2 }}>
                Validation successful. Click Import to proceed.
              </Alert>
            )}

            {seedMutation.isSuccess && seedMutation.data && (
              <Alert severity="success" icon={<CheckCircle />} sx={{ mt: 2 }}>
                <Typography fontWeight={500}>Import successful</Typography>
                <Box component="ul" sx={{ mt: 1, pl: 2 }}>
                  <li>Added: {seedMutation.data.added}</li>
                  <li>Skipped: {seedMutation.data.skipped}</li>
                  {seedMutation.data.errors.length > 0 && (
                    <li>Errors: {seedMutation.data.errors.length}</li>
                  )}
                </Box>
                <Button size="small" variant="text" onClick={() => navigate({ to: '/items/$itemType', params: { itemType } })} sx={{ mt: 1 }}>
                  View {schema.plural_name}
                </Button>
              </Alert>
            )}

            {validateMutation.isError && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {(validateMutation.error as Error).message || 'Validation failed'}
              </Alert>
            )}

            {seedMutation.isError && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {(seedMutation.error as Error).message || 'Import failed'}
              </Alert>
            )}
          </CardContent>
        </Card>
      </Box>
    </Stack>
  );
}
