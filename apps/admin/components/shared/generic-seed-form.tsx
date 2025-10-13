'use client';

import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { getItemTypeConfig } from '@/lib/config/item-types';
import { getItemApi } from '@/lib/api/generic-item-api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { LoadingSpinner } from '@/components/shared/loading-spinner';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ArrowLeft, Upload, CheckCircle, AlertCircle, FileSearch, Link as LinkIcon, FileUp } from 'lucide-react';

interface GenericSeedFormProps {
  itemType: string;
}

type SeedSource = 'url' | 'file';

export function GenericSeedForm({ itemType }: GenericSeedFormProps) {
  const config = getItemTypeConfig(itemType);
  const router = useRouter();
  const queryClient = useQueryClient();
  
  // URL state
  const [url, setUrl] = useState('');
  const [urlError, setUrlError] = useState('');
  
  // File state
  const [file, setFile] = useState<File | null>(null);
  const [fileData, setFileData] = useState<any>(null);
  const [fileError, setFileError] = useState('');
  
  // Common state
  const [isValidated, setIsValidated] = useState(false);
  const [activeTab, setActiveTab] = useState<SeedSource>('file');

  const validateMutation = useMutation({
    mutationFn: (payload: { url?: string; data?: any }) => {
      if (payload.url) {
        return getItemApi(itemType).validate(payload.url);
      } else if (payload.data) {
        return getItemApi(itemType).validateData(payload.data);
      }
      throw new Error('No data provided');
    },
    onSuccess: (data) => {
      if (data.valid) {
        setIsValidated(true);
      }
    },
  });

  const seedMutation = useMutation({
    mutationFn: (payload: { url?: string; data?: any }) => {
      if (payload.url) {
        return getItemApi(itemType).seed(payload.url);
      } else if (payload.data) {
        return getItemApi(itemType).seedData(payload.data);
      }
      throw new Error('No data provided');
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: [itemType, 'list'] });
      setIsValidated(false);
      setUrl('');
      setFile(null);
      setFileData(null);
    },
  });

  // URL handlers
  const handleValidateUrl = async (e: React.FormEvent) => {
    e.preventDefault();
    setUrlError('');
    setIsValidated(false);

    try {
      new URL(url);
    } catch {
      setUrlError('Please enter a valid URL');
      return;
    }

    validateMutation.mutate({ url });
  };

  const handleUrlChange = (newUrl: string) => {
    setUrl(newUrl);
    setIsValidated(false);
    setUrlError('');
    validateMutation.reset();
    seedMutation.reset();
  };

  // File handlers
  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    setFileError('');
    setIsValidated(false);
    validateMutation.reset();
    seedMutation.reset();

    if (!selectedFile) {
      setFile(null);
      setFileData(null);
      return;
    }

    if (!selectedFile.name.endsWith('.json')) {
      setFileError('Please select a JSON file');
      setFile(null);
      setFileData(null);
      return;
    }

    setFile(selectedFile);

    // Read file content
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const jsonData = JSON.parse(event.target?.result as string);
        setFileData(jsonData);
        setFileError('');
      } catch (error) {
        setFileError('Invalid JSON file format');
        setFileData(null);
      }
    };
    reader.onerror = () => {
      setFileError('Failed to read file');
      setFileData(null);
    };
    reader.readAsText(selectedFile);
  };

  const handleValidateFile = () => {
    if (!fileData) {
      setFileError('Please select a valid JSON file');
      return;
    }

    validateMutation.mutate({ data: fileData });
  };

  const handleSeed = () => {
    if (activeTab === 'url') {
      seedMutation.mutate({ url });
    } else {
      seedMutation.mutate({ data: fileData });
    }
  };

  // Generate example JSON based on config
  const exampleJson = {
    [config.labels.plural.toLowerCase()]: [
      Object.fromEntries(
        config.fields
          .filter((f: any) => f.required)
          .map((f: any) => [f.key, f.placeholder || `Example ${f.label.toLowerCase()}`])
      )
    ]
  };

  return (
    <div>
      <div className="flex items-center space-x-4 mb-6">
        <Link href={`/${itemType}`}>
          <Button variant="ghost" size="sm">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to List
          </Button>
        </Link>
        <h1 className="text-3xl font-bold text-gray-900">Seed {config.labels.plural} Data</h1>
      </div>

      <div className="max-w-2xl">
        <Card>
          <CardHeader>
            <CardTitle>Bulk Import</CardTitle>
            <CardDescription>
              Import {config.labels.plural.toLowerCase()} data from a JSON file or remote URL.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as SeedSource)}>
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="file">
                  <FileUp className="w-4 h-4 mr-2" />
                  Upload File
                </TabsTrigger>
                <TabsTrigger value="url">
                  <LinkIcon className="w-4 h-4 mr-2" />
                  From URL
                </TabsTrigger>
              </TabsList>

              <TabsContent value="file" className="space-y-4">
                <div>
                  <label htmlFor="file" className="block text-sm font-medium mb-2">
                    Select JSON File
                  </label>
                  <Input
                    id="file"
                    type="file"
                    accept=".json"
                    onChange={handleFileChange}
                    disabled={validateMutation.isPending || seedMutation.isPending}
                  />
                  {file && (
                    <p className="text-sm text-gray-600 mt-1">
                      Selected: {file.name} ({(file.size / 1024).toFixed(2)} KB)
                    </p>
                  )}
                  {fileError && (
                    <p className="text-sm text-red-600 mt-1">{fileError}</p>
                  )}
                </div>

                <div className="flex space-x-4">
                  {!isValidated ? (
                    <Button
                      type="button"
                      onClick={handleValidateFile}
                      disabled={!fileData || validateMutation.isPending}
                      className="flex-1"
                      variant="outline"
                    >
                      {validateMutation.isPending ? (
                        <>
                          <LoadingSpinner size="sm" />
                          <span className="ml-2">Validating...</span>
                        </>
                      ) : (
                        <>
                          <FileSearch className="w-4 h-4 mr-2" />
                          Validate Data
                        </>
                      )}
                    </Button>
                  ) : (
                    <Button
                      type="button"
                      onClick={handleSeed}
                      disabled={seedMutation.isPending}
                      className="flex-1"
                    >
                      {seedMutation.isPending ? (
                        <>
                          <LoadingSpinner size="sm" />
                          <span className="ml-2">Importing...</span>
                        </>
                      ) : (
                        <>
                          <Upload className="w-4 h-4 mr-2" />
                          Import Data
                        </>
                      )}
                    </Button>
                  )}
                </div>
              </TabsContent>

              <TabsContent value="url" className="space-y-4">
                <form onSubmit={handleValidateUrl} className="space-y-4">
                  <div>
                    <label htmlFor="url" className="block text-sm font-medium mb-2">
                      JSON File URL
                    </label>
                    <Input
                      id="url"
                      type="url"
                      placeholder={`https://example.com/${config.labels.plural.toLowerCase()}.json`}
                      value={url}
                      onChange={(e) => handleUrlChange(e.target.value)}
                      disabled={validateMutation.isPending || seedMutation.isPending}
                    />
                    {urlError && (
                      <p className="text-sm text-red-600 mt-1">{urlError}</p>
                    )}
                  </div>

                  <div className="flex space-x-4">
                    {!isValidated ? (
                      <Button
                        type="submit"
                        disabled={!url || validateMutation.isPending}
                        className="flex-1"
                        variant="outline"
                      >
                        {validateMutation.isPending ? (
                          <>
                            <LoadingSpinner size="sm" />
                            <span className="ml-2">Validating...</span>
                          </>
                        ) : (
                          <>
                            <FileSearch className="w-4 h-4 mr-2" />
                            Validate Data
                          </>
                        )}
                      </Button>
                    ) : (
                      <Button
                        type="button"
                        onClick={handleSeed}
                        disabled={seedMutation.isPending}
                        className="flex-1"
                      >
                        {seedMutation.isPending ? (
                          <>
                            <LoadingSpinner size="sm" />
                            <span className="ml-2">Importing...</span>
                          </>
                        ) : (
                          <>
                            <Upload className="w-4 h-4 mr-2" />
                            Import Data
                          </>
                        )}
                      </Button>
                    )}
                  </div>
                </form>
              </TabsContent>
            </Tabs>

            <Alert className="mt-4">
              <AlertCircle className="h-4 w-4" />
              <AlertTitle>Expected JSON Format</AlertTitle>
              <AlertDescription>
                <pre className="mt-2 text-xs bg-gray-50 p-2 rounded overflow-x-auto">
                  {JSON.stringify(exampleJson, null, 2)}
                </pre>
              </AlertDescription>
            </Alert>

            {validateMutation.isSuccess && validateMutation.data && !validateMutation.data.valid && (
              <Alert variant="destructive" className="mt-4">
                <AlertCircle className="h-4 w-4" />
                <AlertTitle>Validation Failed</AlertTitle>
                <AlertDescription>
                  <ul className="mt-2 space-y-1 text-sm">
                    {validateMutation.data.errors.map((error: any, index: number) => (
                      <li key={index}>• {error}</li>
                    ))}
                  </ul>
                </AlertDescription>
              </Alert>
            )}

            {isValidated && !seedMutation.isSuccess && (
              <Alert className="mt-4 border-green-200 bg-green-50">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <AlertTitle className="text-green-900">Validation Successful!</AlertTitle>
                <AlertDescription className="text-green-800">
                  The JSON structure is valid and ready for import. Click &quot;Import Data&quot; to proceed.
                </AlertDescription>
              </Alert>
            )}

            {seedMutation.isSuccess && seedMutation.data && (
              <Alert className="mt-4 border-green-200 bg-green-50">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <AlertTitle className="text-green-900">Import Successful!</AlertTitle>
                <AlertDescription className="text-green-800">
                  <ul className="mt-2 space-y-1 text-sm">
                    <li>✓ Added: {seedMutation.data.added} {config.labels.plural.toLowerCase()}</li>
                    <li>⊘ Skipped: {seedMutation.data.skipped} (already exist)</li>
                    {seedMutation.data.errors.length > 0 && (
                      <li className="text-red-600">
                        ✗ Errors: {seedMutation.data.errors.length}
                      </li>
                    )}
                  </ul>
                  <Button
                    variant="outline"
                    size="sm"
                    className="mt-3"
                    onClick={() => router.push(`/${itemType}`)}
                  >
                    View {config.labels.plural}
                  </Button>
                </AlertDescription>
              </Alert>
            )}

            {validateMutation.isError && (
              <Alert variant="destructive" className="mt-4">
                <AlertCircle className="h-4 w-4" />
                <AlertTitle>Validation Failed</AlertTitle>
                <AlertDescription>
                  {(validateMutation.error as Error).message || 'Failed to validate data. Please check your input and try again.'}
                </AlertDescription>
              </Alert>
            )}

            {seedMutation.isError && (
              <Alert variant="destructive" className="mt-4">
                <AlertCircle className="h-4 w-4" />
                <AlertTitle>Import Failed</AlertTitle>
                <AlertDescription>
                  {(seedMutation.error as Error).message || 'Failed to import data. Please try again.'}
                </AlertDescription>
              </Alert>
            )}
          </CardContent>
        </Card>

        <Card className="mt-6">
          <CardHeader>
            <CardTitle>Import Process</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-gray-600 space-y-2">
            <p>• <strong>Step 1:</strong> Choose file upload or URL</p>
            <p>• <strong>Step 2:</strong> Validate JSON structure and format</p>
            <p>• <strong>Step 3:</strong> Review validation results</p>
            <p>• <strong>Step 4:</strong> Import data if validation passes</p>
            <p>• <strong>Natural Key Matching:</strong> Detects and skips duplicates</p>
            <p>• <strong>User-Safe:</strong> Only adds new items, never overwrites existing data</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
