import { Box, Card, CardActionArea, CardContent, Skeleton, Typography } from '@mui/material';
import ArrowForward from '@mui/icons-material/ArrowForward';
import { Link } from '@tanstack/react-router';
import { resolveIcon } from '../../lib/icons/icon-registry';
import { getAccentColor } from '../../theme';

interface Props {
  itemType: string;
  displayName: string;
  icon: string;
  color: string;
  totalItems: number;
  isLoading?: boolean;
}

export function ItemTypeCard({ itemType, displayName, icon, color, totalItems, isLoading }: Props) {
  const Icon = resolveIcon(icon);
  // ponytail: schema.color drives the icon tint via M3 "tonal" container
  // (alpha-blended onto surfaceContainerHighest), not a custom hex background.
  const accent = getAccentColor(color);

  return (
    <Card>
      <CardActionArea component={Link} to={`/items/${itemType}`}>
        <CardContent sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5 }}>
            <Box
              sx={{
                width: 56,
                height: 56,
                borderRadius: '16px',
                bgcolor: 'surfaceContainerHighest',
                color: accent,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Icon sx={{ fontSize: 28 }} />
            </Box>
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Typography variant="titleMedium" sx={{ mb: 0.5 }}>
                {displayName}
              </Typography>
              {isLoading ? (
                <Skeleton width={140} />
              ) : (
                <>
                  <Typography variant="body2" color="onSurfaceVariant">
                    {totalItems} {totalItems === 1 ? 'item' : 'items'} available
                  </Typography>
                  <Typography variant="labelLarge" sx={{ color: accent, mt: 0.5 }}>
                    View all {displayName.toLowerCase()}
                  </Typography>
                </>
              )}
            </Box>
            <ArrowForward sx={{ color: 'onSurfaceVariant' }} />
          </Box>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}
