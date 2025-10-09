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
import { ArrowLeft, Upload, CheckCircle, AlertCircle, FileSearch } from 'lucide-react';

interface GenericSeedFormProps {
  itemType: string;
}

export function GenericSeedForm({ itemType }: GenericSeedFormProps) {
  const config = getItemTypeConfig(itemType);
  const router = useRouter();
  const queryClient = useQueryClient();
  const [url, setUrl] = useState('');
  const [urlError, setUrlError] = useState('');
  const [isValidated, setIsValidated] = useState(false);

  const validateMutation = useMutation({
    mutationFn: (url: string) => getItemApi(itemType).validate(url),
    onSuccess: (data) => {
      if (data.valid) {
        setIsValidated(true);
      }
    },
  });

  const seedMutation = useMutation({
    mutationFn: (url: string) => getItemApi(itemType).seed(url),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: [itemType, 'list'] });
      setIsValidated(false);
      setUrl('');
    },
  });

  const handleValidate = async (e: React.FormEvent) => {
    e.preventDefault();
    setUrlError('');
    setIsValidated(false);

    // Validate URL format
    try {
      new URL(url);
    } catch {
      setUrlError('Please enter a valid URL');
      return;
    }

    validateMutation.mutate(url);
  };

  const handleSeed = () => {
    seedMutation.mutate(url);
  };

  const handleUrlChange = (newUrl: string) => {
    setUrl(newUrl);
    setIsValidated(false);
    setUrlError('');
    validateMutation.reset();
    seedMutation.reset();
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
            <CardTitle>Bulk Import from URL</CardTitle>
            <CardDescription>
              Import {config.labels.plural.toLowerCase()} data from a remote JSON file. The file should contain an array of {config.labels.singular.toLowerCase()} objects.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleValidate} className="space-y-4">
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

              <Alert>
                <AlertCircle className="h-4 w-4" />
                <AlertTitle>Expected JSON Format</AlertTitle>
                <AlertDescription>
                  <pre className="mt-2 text-xs bg-gray-50 p-2 rounded overflow-x-auto">
                    {JSON.stringify(exampleJson, null, 2)}
                  </pre>
                </AlertDescription>
              </Alert>

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
                  {(validateMutation.error as Error).message || 'Failed to validate data. Please check the URL and try again.'}
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
            <p>• <strong>Step 1:</strong> Validate JSON structure and format</p>
            <p>• <strong>Step 2:</strong> Review validation results</p>
            <p>• <strong>Step 3:</strong> Import data if validation passes</p>
            <p>• <strong>Natural Key Matching:</strong> Uses name + origin to identify duplicates</p>
            <p>• <strong>User-Safe:</strong> Only adds new items, never overwrites existing data</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
